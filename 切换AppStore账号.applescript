-- Script: 切换AppStore账号
-- Version: 2.2.7 (调整登录对话框初始等待为1.5s)
-- Author: Cascade AI & USER

-- 全局日志记录器
global scriptLog

-- 用户账户信息 (确保密码准确)
property account1User : "alexcopd@gmail.com"
property account1Pass : "6954236Tom"
property account2User : "cyjcz0214@gmail.com"
property account2Pass : "Alex6.30Cyj"

-- 菜单项本地化文本 (使用属性确保它们在处理程序中可用)
property menuStoreTextZh : "商店"
property menuSignOutTextZh : "退出登录"
property menuLoginTextZh : "登录"

property menuStoreTextEn : "Store"
property menuSignOutTextEn : "Sign Out"
property menuLoginTextEn : "Sign In"

-- 主执行块
on run
	set scriptLog to {} -- 初始化移到此处
	my logDetail("========= App Store Account Switcher Script Started (v2.2.7) =========")
	my logDetail("Predefined Account 1: " & account1User)
	my logDetail("Predefined Account 2: " & account2User)
	
	set targetUser to ""
	set targetPass to ""
	
	try
		my logDetail("Displaying account selection dialog to user.")
		display dialog "请选择要操作的 App Store 账号：" buttons {"账号1", "账号2", "仅退出当前账号"} default button "账号1" with title "App Store 账号切换器"
		set dialogResult to result
		set choice to button returned of dialogResult
		my logDetail("User selected: '" & choice & "'.")
		
		if choice is "账号1" then
			set targetUser to account1User
			set targetPass to account1Pass
			my logDetail("Target account set to Account 1: " & targetUser)
		else if choice is "账号2" then
			set targetUser to account2User
			set targetPass to account2Pass
			my logDetail("Target account set to Account 2: " & targetUser)
		else if choice is "仅退出当前账号" then
			my logDetail("User chose '仅退出当前账号'.")
		end if
		
		my logDetail("Step 1: Attempting to sign out from App Store...")
		performSignOut()
		
		if choice is "仅退出当前账号" then
			my logDetail("Sign-out only operation complete. Script will now finalize.")
			error number -128 -- User cancellation to trigger final log display
		end if
		
		my logDetail("Step 2: Attempting to click the 'Sign In' / '登录' menu item...")
		set signInClickedSuccessfully to clickSignInMenu()
		
		my logDetail("Step 3: Processing login.")
		if signInClickedSuccessfully then
			my logDetail("Successfully clicked the sign-in menu item. Attempting automatic credential input...")
			set autoInputSuccess to my performAutoLogin(targetUser, targetPass)
			
			if not autoInputSuccess then
				my logDetail("Automatic credential input FAILED or was skipped. Falling back to manual input prompt.")
				display dialog "自动输入账号密码失败或出错。App Store 登录窗口应已出现。请手动输入以下账号信息：" & return & return & "Apple ID: " & targetUser & return & "密码: " & targetPass with title "手动登录信息" buttons {"好的"} default button "好的"
				my logDetail("User acknowledged manual input dialog after auto-input failure.")
			else
				my logDetail("Automatic credential input reported as successful or attempted.")
				display dialog "已尝试自动输入账号密码。请检查 App Store 登录状态。" buttons {"好的"} default button "好的" giving up after 5
				my logDetail("Brief dialog shown after auto-input attempt.")
			end if
		else
			my logDetail("Failed to click the sign-in menu item, or it was not found/enabled.")
			my logDetail("Displaying fallback dialog to guide user for manual sign-in via App Store or System Settings.")
			display dialog "未能自动点击 App Store 中的“登录”或“Sign In”选项（可能已登录、菜单项不存在或未启用）。" & return & return & "请检查 App Store 界面，或尝试通过 系统设置 > Apple ID > 媒体与购买项目 手动登录。" & return & return & "目标账号信息:" & return & "Apple ID: " & targetUser with title "操作提示：手动登录" buttons {"好的"} default button "好的"
			my logDetail("User acknowledged fallback dialog for sign-in menu click failure.")
		end if
		
		my logDetail("Main script logic complete.")
		
	on error errMsg number errNum
		if errNum is -128 then
			my logDetail("Script flow ended (possibly user cancellation or 'sign out only'). Finalizing.")
		else
			my logDetail("UNHANDLED ERROR in main block: " & errMsg & " (Number: " & errNum & ")")
		end if
	end try
	
	finalizeScript()
end run

-- 处理程序: 执行退出登录操作 (内容与v2.1一致，此处省略以减少重复)
on performSignOut()
	my logDetail("performSignOut handler started.")
	set signOutAttempted to false
	set signOutSuccessful to false
	try
		my logDetail("Activating App Store for sign-out.")
		tell application "App Store"
			activate
			delay 0.5 -- Time for App Store to become responsive
		end tell
		
		my logDetail("Interacting with System Events for App Store menu (sign-out).")
		tell application "System Events"
			tell process "App Store"
				set menuBar to menu bar 1
				my logDetail("Checking for Chinese sign-out menu: '" & menuSignOutTextZh & "' in '" & menuStoreTextZh & "'.")
				if exists menu item menuSignOutTextZh of menu menuStoreTextZh of menuBar then
					if enabled of menu item menuSignOutTextZh of menu menuStoreTextZh of menuBar then
						my logDetail("Found and enabled Chinese sign-out menu. Clicking.")
						click menu item menuSignOutTextZh of menu menuStoreTextZh of menuBar
						set signOutAttempted to true
						set signOutSuccessful to true
						my logDetail("Clicked Chinese '" & menuSignOutTextZh & "'.")
					else
						my logDetail("Chinese sign-out menu '" & menuSignOutTextZh & "' found but IS NOT ENABLED.")
						set signOutAttempted to true
					end if
				else
					my logDetail("Chinese sign-out menu NOT found. Checking English: '" & menuSignOutTextEn & "' in '" & menuStoreTextEn & "'.")
					if exists menu item menuSignOutTextEn of menu menuStoreTextEn of menuBar then
						if enabled of menu item menuSignOutTextEn of menu menuStoreTextEn of menuBar then
							my logDetail("Found and enabled English sign-out menu. Clicking.")
							click menu item menuSignOutTextEn of menu menuStoreTextEn of menuBar
							set signOutAttempted to true
							set signOutSuccessful to true
							my logDetail("Clicked English '" & menuSignOutTextEn & "'.")
						else
							my logDetail("English sign-out menu '" & menuSignOutTextEn & "' found but IS NOT ENABLED.")
							set signOutAttempted to true
						end if
					else
						my logDetail("Sign-out menu NOT FOUND in either language. App might be already signed out or UI changed.")
					end if
				end if
			end tell
		end tell
		
		if signOutAttempted and signOutSuccessful then
			my logDetail("Sign-out click command sent. Delaying for UI update (1.0s).")
			delay 1.0 -- Optimal delay for UI to update
		else if signOutAttempted and not signOutSuccessful then
			my logDetail("Sign-out menu was found but not enabled. No click performed. No delay needed for UI update from click.")
		else
			my logDetail("No sign-out menu item was clicked (not found). No delay needed for UI update from click.")
		end if
		
	on error errMsg number errNum
		my logDetail("ERROR in performSignOut handler: " & errMsg & " (Number: " & errNum & ")")
		display dialog "尝试从 App Store 退出登录时发生错误：" & return & errMsg & return & "请检查“辅助功能”权限，或手动操作。" with title "退出操作错误" buttons {"好的"} default button 1
		my logDetail("performSignOut handler terminated due to error.")
	end try
	my logDetail("performSignOut handler finished.")
end performSignOut

-- 处理程序: 点击登录/Sign In菜单项 (内容与v2.1一致，此处省略以减少重复)
on clickSignInMenu()
	my logDetail("clickSignInMenu handler started.")
	set clickedSuccessfully to false
	try
		my logDetail("Activating App Store for sign-in menu click.")
		tell application "App Store"
			activate
			delay 0.2 -- Optimal delay for App Store to activate
		end tell
		
		my logDetail("Interacting with System Events for App Store menu (sign-in).")
		tell application "System Events"
			tell process "App Store"
				set menuBar to menu bar 1
				my logDetail("Checking for Chinese sign-in menu: '" & menuLoginTextZh & "' in '" & menuStoreTextZh & "'.")
				if exists menu item menuLoginTextZh of menu menuStoreTextZh of menuBar then
					if enabled of menu item menuLoginTextZh of menu menuStoreTextZh of menuBar then
						my logDetail("Found and enabled Chinese sign-in menu. Clicking.")
						click menu item menuLoginTextZh of menu menuStoreTextZh of menuBar
						my logDetail("Clicked Chinese '" & menuLoginTextZh & "'. Delaying for login dialog (0.3s).")
						delay 0.3 -- Post-click delay for dialog
						set clickedSuccessfully to true
					else
						my logDetail("Chinese sign-in menu '" & menuLoginTextZh & "' found but IS NOT ENABLED.")
					end if
				end if
				
				if not clickedSuccessfully then
					my logDetail("Chinese sign-in not successful or not found. Checking English: '" & menuLoginTextEn & "' in '" & menuStoreTextEn & "'.")
					if exists menu item menuLoginTextEn of menu menuStoreTextEn of menuBar then
						if enabled of menu item menuLoginTextEn of menu menuStoreTextEn of menuBar then
							my logDetail("Found and enabled English sign-in menu. Clicking.")
							click menu item menuLoginTextEn of menu menuStoreTextEn of menuBar
							my logDetail("Clicked English '" & menuLoginTextEn & "'. Delaying for login dialog (0.3s).")
							delay 0.3
							set clickedSuccessfully to true
						else
							my logDetail("English sign-in menu '" & menuLoginTextEn & "' found but IS NOT ENABLED.")
						end if
					else
						my logDetail("Sign-in menu NOT FOUND in Chinese or English.")
					end if
				end if
			end tell
		end tell
		
	on error errMsg number errNum
		my logDetail("ERROR in clickSignInMenu handler: " & errMsg & " (Number: " & errNum & ")")
		set clickedSuccessfully to false
	end try
	
	if clickedSuccessfully then
		my logDetail("clickSignInMenu: Successfully clicked a sign-in menu item.")
	else
		my logDetail("clickSignInMenu: FAILED to click any sign-in menu item or none were suitable.")
	end if
	my logDetail("clickSignInMenu handler finished.")
	return clickedSuccessfully
end clickSignInMenu

-- 新处理程序: 执行自动登录 (输入账号密码)
on performAutoLogin(appleID, pass)
	my logDetail("performAutoLogin handler started for user: " & appleID)
	local autoLoginAttempted, autoLoginSucceeded
	set autoLoginAttempted to false
	set autoLoginSucceeded to false
	
	try
		my logDetail("Waiting for App Store login dialog to appear (initial delay: 1.5 seconds).")
		-- This delay is crucial and might need adjustment based on system performance.
		-- A more robust solution would involve checking for the login window/sheet's existence.
		delay 1.5
		
		my logDetail("Ensuring 'App Store' process is frontmost for System Events.")
		tell application "System Events"
			tell process "App Store"
				if not frontmost then
					my logDetail("'App Store' process was not frontmost. Setting frontmost to true.")
					set frontmost to true
					delay 0.5 -- Give time for window to gain focus
				end if
				
				-- At this point, the App Store's login dialog (often a sheet) should be active and ready for input.
				-- The Apple ID field is typically focused by default.
				my logDetail("Attempting to keystroke Apple ID: [REDACTED FOR LOG]")
				keystroke appleID
				set autoLoginAttempted to true -- Marked as attempted once we start keystroking
				delay 0.5 -- Short delay after typing Apple ID
				
				my logDetail("Keystroking RETURN to submit Apple ID.")
				keystroke return
				my logDetail("Delaying for 0.5 seconds to allow password field to appear after Apple ID submission.")
				delay 0.5 -- Adjusted delay for App Store to process Apple ID and present password field
				
				my logDetail("Attempting to keystroke password: [REDACTED FOR LOG]")
				keystroke pass
				delay 0.5 -- Short delay after typing password
				
				my logDetail("Keystroking RETURN to submit login credentials.")
				keystroke return
				
				set autoLoginSucceeded to true -- Assume success if all keystrokes are sent without error.
				-- Actual login success depends on App Store's validation.
				my logDetail("All auto-input keystrokes (ID, Return, Password, Return) sent for two-step login.")
			end tell
		end tell
		
	on error errMsg number errNum
		my logDetail("ERROR in performAutoLogin handler: " & errMsg & " (Number: " & errNum & ")")
		set autoLoginSucceeded to false -- Ensure it's marked as failed on error
	end try
	
	if autoLoginSucceeded then
		my logDetail("performAutoLogin: Keystroke sequence completed successfully.")
	else
		my logDetail("performAutoLogin: FAILED or an error occurred during keystroke sequence.")
	end if
	return autoLoginSucceeded
end performAutoLogin


-- 辅助处理程序: 详细日志记录 (带时间戳) (内容与v2.1一致，此处省略)
on logDetail(messageText)
	try
		set timestamp to time string of (current date)
		set finalMessage to "[" & timestamp & "] " & messageText
		tell scriptLog to copy finalMessage to its end
	on error
		-- Fallback if logging itself fails
	end try
end logDetail

-- 辅助处理程序: 合并日志列表为字符串 (内容与v2.1一致，此处省略)
on joinLogs(logList)
	set prevDelimiters to AppleScript's text item delimiters
	set AppleScript's text item delimiters to return
	set joinedString to logList as string
	set AppleScript's text item delimiters to prevDelimiters
	return joinedString
end joinLogs

-- 辅助处理程序: 脚本结束时的操作 (显示日志) (内容与v2.1一致，此处省略)
on finalizeScript()
	my logDetail("========= App Store Account Switcher Script Finished (v2.2.7) =========")
	
	log ""
	log "--- Script Log Start ---"
	repeat with logEntry in scriptLog
		log logEntry -- Log each entry individually to the terminal
	end repeat
	log "--- Script Log End ---"
	log ""
	
	-- Prepare the full log for clipboard (joined as a single string)
	set fullLogTextForClipboard to joinLogs(scriptLog)
	set the clipboard to fullLogTextForClipboard
	
	-- Log a final message to terminal indicating clipboard copy
	log "--- Full log also copied to clipboard. ---"
end finalizeScript

