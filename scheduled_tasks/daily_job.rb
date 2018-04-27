class DailyJob < Scheduler::SchedulerTask
  #every '2s'
  #self.in '2s'
  #self.cron '00 05 * * *'
  #self.cron '30 12 * * *'
  every '6h', :first_at => Chronic.parse('tomorrow 3.30 am')
  #cron '* 8 0 0 0'  # cron style (run every 4 am)
  #cron '* 9 0 0 0'  # cron style (run every 4 am)

  def run
    log("Daily Job start at #{Time.now}")
    sql = Sql.new
    sql.z_execute
    sql.z_update_ygt
    log("Daily Job finish at #{Time.now}")
  end


end