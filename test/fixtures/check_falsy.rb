class CheckFalsyView < Tache
  def number
    lambda do |text|
      render text
    end
  end
end

CheckFalsyView