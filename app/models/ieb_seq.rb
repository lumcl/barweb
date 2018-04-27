class IebSeq < ActiveRecord::Base

  def self.next_val(sequence,first_val)
    val = first_val
    IebSeq.transaction do
      ieb_seq = IebSeq.where(seq: sequence).first
      if ieb_seq
        ieb_seq.lock!
        ieb_seq.lastval += 1
        ieb_seq.save!
        val = ieb_seq.lastval
      else
        ieb_seq = IebSeq.create!(seq: sequence, lastval: first_val)
        val = ieb_seq.lastval
      end
    end
    val
  end


end
