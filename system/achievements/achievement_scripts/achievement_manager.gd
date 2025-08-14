class_name AchievementManager

static func unlock_achievement(ach_name : String):
	var status = Steam.getAchievement(ach_name)
	
	if status["achieved"]:
		print("Achievement %s already unlocked" % [ach_name])
		return
	
	Steam.setAchievement(ach_name)
	Steam.storeStats()
