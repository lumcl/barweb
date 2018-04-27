class InsertSapsr3 < Scheduler::SchedulerTask
  #every '2s'
  #self.in '2s'
  #self.cron '00 05 * * *'
  #self.cron '30 12 * * *'
  every '24h', :first_at => Chronic.parse('tomorrow 2.30 am')
  #cron '* 8 0 0 0'  # cron style (run every 4 am)
  #cron '* 9 0 0 0'  # cron style (run every 4 am)

  def run
    log("Insert Sapsr3 start at #{Time.now}")
    Sql.insert_sapsr3
    log("Insert Sapsr3 finish at #{Time.now}")
  end

end