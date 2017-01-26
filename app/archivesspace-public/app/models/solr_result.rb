class SOLRResult
  attr_reader :raw, :json

  def initialize(solr_result)
    @raw = solr_result
    @json = solr_result['json'] # already parsed! JSON.parse(solr_result['json'])
  end

  def subjects
    return @subjects if @subjects

    @subjects = []

    Array(json['subjects']).each do |subject|
      unless subject['_resolved'].blank?
        sub = title_and_uri(subject['_resolved'], subject['_inherited'])
        @subjects.push(sub) if sub
      end
    end

    @subjects
  end

  def agents
    return @agents if @agents 

    @agents = {}

    Array(json['linked_agents']).each do |agent|
      unless agent['role'].blank? || agent['_resolved'].blank?
        role = agent['role']
        ag = title_and_uri(agent['_resolved'], agent['_inherited'])
        if role == 'subject'
          subjects.push(ag) if ag
        elsif ag
          @agents[role] = @agents[role].blank? ? [ag] : @agents[role].push(ag)
        end
      end
    end
    subjects.sort_by! { |hsh| hsh['title'] }

    @agents
  end

  def extents
    return @extents if @extents

    @extents = []

    Array(json['extents']).each do |ext|
      type = I18n.t("enumerations.extent_extent_type.#{ext['extent_type']}", default: ext['extent_type'])
      display = I18n.t('extent_number_type', :number => ext['number'], :type => type)
      summ = ext['container_summary'] || ''
      summ = "(#{summ})" unless summ.blank? || ( summ.start_with?('(') && summ.end_with?(')'))  # yeah, I coulda done this with rexep.
      display << ' ' << summ
      display << I18n.t('extent_phys_details',:deets => ext['physical_details']) unless  ext['physical_details'].blank?
      display << I18n.t('extent_dims', :dimensions => ext['dimensions']) unless  ext['dimensions'].blank?

      @extents << {'display' => display, '_inherited' => ext.dig('_inherited')}
    end

    @extents
  end

  def dates
    return @dates if @dates

    @dates = [] 

    Array(json['dates']).each do |date|
      label = date['label'].blank? ? '' : "#{date['label'].titlecase}: "
      label = '' if label == 'Creation: '
      exp =  date['expression'] || ''
      if exp.blank?
        exp = date['begin'] unless date['begin'].blank?
        unless date['end'].blank?
          exp = (exp.blank? ? '' : exp + '-') + date['end']
        end
      end
      if date['date_type'] == 'bulk'
        exp = exp.sub('bulk','').sub('()', '').strip
        exp = date['begin'] == date['end'] ? I18n.t('bulk._singular', :dates => exp) :
          I18n.t('bulk._plural', :dates => exp)
      end

      @dates.push({'final_expression' => label + exp, '_inherited' => date.dig('_inherited')})
    end

    @dates
  end

  def notes
    return @notes if @notes

    @notes = {}

    Array(json['notes']).each do |note|
      type = note_type(note)
      if note['publish']
        note_struct = handle_note_structure(note, type)
        if @notes.has_key? type
          if @notes[type]['label'].blank?
            @notes[type]['label'] = note_struct['label']
          elsif @notes[type]['label'] != note_struct['label']
            #add a secondary label as an inline label
            note_struct['note_text']= "<span class='inline-label'>#{note_struct['label']}</span> #{note_struct['note_text']}"
          end
          @notes[type]['note_text'] = "#{notes_hash[type]['note_text']}<br/> #{note_struct['note_text']}"
        else
          @notes[type] = note_struct
        end
      end
    end

    @notes
  end

  private

  def set_up_note(notes_hash, type, note)
 
  end

  def handle_note_structure(note, type)
    note_struct = {}
    note_text = ''
    if note['publish'] || defined?(AppConfig[:ignore_false])  # temporary switch due to ingest issues
      label = note.has_key?('label') ? note['label'] :  I18n.t("enumerations._note_types.#{type}", :default => '')
      note_struct['label'] = label
      inherit = inheritance(note['_inherited'])
      if note['jsonmodel_type'] == 'note_multipart' || !note['subnotes'].blank?
        notes = []
        note['subnotes'].each do |sub|
          notes.push(handle_single_note(sub, note_text))
        end
        note_text = notes.join("<br/>")
      else
        note_text = handle_single_note(note, note_text)
      end
    end
    note_struct['note_text'] = inherit + note_text
    note_struct
  end

end