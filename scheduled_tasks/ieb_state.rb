class IebState < Scheduler::SchedulerTask
  every '20m'
  #self.in '2s'
  #self.cron '00 05 * * *'
  #self.cron '30 12 * * *'
  #every '24h', :first_at => Chronic.parse('tomorrow 2.30 am')
  #cron '* 8 0 0 0'  # cron style (run every 4 am)
  #cron '* 9 0 0 0'  # cron style (run every 4 am)

  def run
    log("Insert IebState start at #{Time.now}")
    YgtPreEms3OrgBomState.update_sap
    YgtPreEms3OrgExgState.upload_sap
    YgtPreEms3OrgImgState.upload_sap
    YgtDecHeadState.update_sap
    log("Insert IebState finish at #{Time.now}")
  end

end