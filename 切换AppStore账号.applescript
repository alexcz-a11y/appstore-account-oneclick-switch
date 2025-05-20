-- Script: 切换AppStore账号
-- Version: 2.4.0 (集成钥匙串读取/保存凭据功能)
-- Author: Cascade AI & USER

-- 全局日志记录器
global scriptLog

-- 用户账户信息将在运行时输入或从钥匙串读取
property keychainServicePrefix : "applescript.AppStoreAccountSwitcher." -- 用于钥匙串服务名的前缀

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
	my logDetail("========= App Store Account Switcher Script Started (v2.4.0) =========")
	my logDetail("Script ready for user to input account details.")
	
	set targetUser to ""
	set targetPass to ""
	
	try
		my logDetail("Displaying account selection dialog to user.")
		display dialog "请选择要操作的 App Store 账号：" buttons {"账号1", "账号2", "仅退出当前账号"} default button "账号1" with title "App Store 账号切换器"
		set dialogResult to result
		set choice to button returned of dialogResult
		my logDetail("User selected option: '" & choice & "'.")
		
		if choice is "账号1" or choice is "账号2" then
			set accountSlotName to choice -- "账号1" or "账号2"
			set resolvedAppleID to missing value
			set resolvedPassword to missing value
			
			-- 构建钥匙串服务名
			set appleIDService to keychainServicePrefix & accountSlotName & ".AppleID"
			set passwordService to keychainServicePrefix & accountSlotName & ".Password"
			
			-- 尝试从钥匙串读取
			set resolvedAppleID to my readFromKeychain(appleIDService, accountSlotName)
			set resolvedPassword to my readFromKeychain(passwordService, accountSlotName)
			
			if resolvedAppleID is missing value or resolvedAppleID is "" or resolvedPassword is missing value or resolvedPassword is "" then
				my logDetail("Credentials for " & accountSlotName & " not fully retrieved from Keychain or empty. Prompting user.")
				
				set currentAppleIDValue to ""
				if resolvedAppleID is not missing value and resolvedAppleID is not "" then
					set currentAppleIDValue to resolvedAppleID
				end if
				
				display dialog "钥匙串中未找到 " & accountSlotName & " 的完整登录信息，或信息不完整。" & return & return & "请输入 " & accountSlotName & " 的 Apple ID:" default answer currentAppleIDValue with title (accountSlotName & " - Apple ID")
				set tempUser to text returned of result
				if tempUser is "" then
					my logDetail("User did not enter an Apple ID for " & accountSlotName & ". Aborting.")
					display dialog "未输入Apple ID，脚本已中止。" buttons {"好的"} default button 1 icon stop
					error "Apple ID cannot be empty." number -128
				end if
				
				display dialog "请输入 " & accountSlotName & " ('" & tempUser & "') 的密码:" default answer "" with hidden answer with title (accountSlotName & " - 密码")
				set tempPass to text returned of result
				if tempPass is "" then
					my logDetail("User did not enter a password for " & accountSlotName & ". Aborting.")
					display dialog "未输入密码，脚本已中止。" buttons {"好的"} default button 1 icon stop
					error "Password cannot be empty." number -128
				end if
				
				set resolvedAppleID to tempUser
				set resolvedPassword to tempPass
				
				-- 询问是否保存到钥匙串
				display dialog "您想将 " & accountSlotName & " (" & resolvedAppleID & ") 的登录信息保存到钥匙串，以便下次自动使用吗？" buttons {"不保存", "保存"} default button "保存" with title "保存到钥匙串？"
				if button returned of result is "保存" then
					my saveToKeychain(appleIDService, accountSlotName, resolvedAppleID)
					my saveToKeychain(passwordService, accountSlotName, resolvedPassword)
				else
					my logDetail("User chose not to save credentials for " & accountSlotName & " to Keychain.")
					-- 如果用户选择不保存，下次仍然会提示输入。如果希望清除已有的（如果存在），则需额外逻辑。
				end if
			else
				my logDetail("Successfully retrieved credentials for " & accountSlotName & " from Keychain: " & resolvedAppleID & " (Password not logged)")
			end if
			
			set targetUser to resolvedAppleID
			set targetPass to resolvedPassword
			my logDetail("Target account for " & accountSlotName & " set to: " & targetUser & " (Password not logged)")
		else if choice is "仅退出当前账号" then
			my logDetail("User chose '仅退出当前账号'.")
			set targetUser to "" -- Not needed for sign out only
			set targetPass to "" -- Not needed for sign out only
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
				-- Since credentials are now user-provided, this dialog is more of a reminder of what they entered.
				display dialog "自动输入账号密码失败或出错。App Store 登录窗口应已出现。请使用您刚才输入的以下账号信息手动登录：" & return & return & "Apple ID: " & targetUser & return & "密码: [已隐藏]" with title "手动登录指引" buttons {"好的"} default button "好的"
				my logDetail("User acknowledged manual input dialog after auto-input failure for user: " & targetUser)
			else
				my logDetail("Automatic credential input reported as successful or attempted.")
				display dialog "已尝试自动输入账号密码。请检查 App Store 登录状态。" buttons {"好的"} default button "好的" giving up after 5
				my logDetail("Brief dialog shown after auto-input attempt.")
			end if
		else
			my logDetail("Failed to click the sign-in menu item, or it was not found/enabled.")
			my logDetail("Displaying fallback dialog to guide user for manual sign-in via App Store or System Settings.")
			display dialog "未能自动点击 App Store 中的“登录”或“Sign In”选项（可能已登录、菜单项不存在或未启用）。" & return & return & "请检查 App Store 界面，或尝试通过 系统设置 > Apple ID > 媒体与购买项目 手动登录。" & return & return & "目标账号信息:" & return & "Apple ID: " & targetUser with title "操作提示：手动登录" buttons {"好的"} default button "好的"
			my logDetail("User acknowledged fallback dialog for sign-in menu click failure for user: " & targetUser)
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
	my logDetail("performAutoLogin handler started for user: " & appleID & " (Password not logged)")
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
	my logDetail("========= App Store Account Switcher Script Finished (v2.4.0) =========")
	
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

-- 新增处理程序: 保存到钥匙串
on saveToKeychain(serviceName as string, accountNameForKeychainSlot as string, valueToSave as string)
	my logDetail("Attempting to save to Keychain: Service='" & serviceName & "', AccountSlot='" & accountNameForKeychainSlot & "'")
	try
		-- 使用 -U 标志来更新现有项目或创建新项目
		do shell script "security add-generic-password -s " & quoted form of serviceName & " -a " & quoted form of accountNameForKeychainSlot & " -w " & quoted form of valueToSave & " -U"
		my logDetail("Successfully saved/updated Keychain item: Service='" & serviceName & "', AccountSlot='" & accountNameForKeychainSlot & "'.")
		return true
	on error errMsg number errNum
		my logDetail("Error saving to Keychain (Service='" & serviceName & "', AccountSlot='" & accountNameForKeychainSlot & "'): " & errMsg & " (Error " & errNum & ")")
		display dialog "保存登录信息到钥匙串时发生错误：" & return & errMsg & return & return & "服务名: " & serviceName & return & "账号槽: " & accountNameForKeychainSlot buttons {"好的"} default button 1 with icon stop
		return false
	end try
end saveToKeychain

-- 新增处理程序: 从钥匙串读取
on readFromKeychain(serviceName as string, accountNameForKeychainSlot as string)
	my logDetail("Attempting to read from Keychain: Service='" & serviceName & "', AccountSlot='" & accountNameForKeychainSlot & "'")
	try
		set itemValue to do shell script "security find-generic-password -s " & quoted form of serviceName & " -a " & quoted form of accountNameForKeychainSlot & " -w"
		if itemValue is not "" then
			my logDetail("Successfully read Keychain item: Service='" & serviceName & "', AccountSlot='" & accountNameForKeychainSlot & "'. Value retrieved.")
			return itemValue
		else
			my logDetail("Keychain item found (Service='" & serviceName & "', AccountSlot='" & accountNameForKeychainSlot & "') but value is empty.")
			return "" -- 返回空字符串表示找到但为空，区别于 missing value
		end if
	on error errMsg number errNum
		-- errKCItemNotFound (项未找到) 的错误码是 -25300
		-- "The specified item could not be found in the keychain" 也是常见的未找到提示
		if errNum is -25300 or errNum is -128 then -- -128 (userCanceledErr) 如果 security 命令因权限等原因被取消
			my logDetail("Keychain item not found or access denied/canceled (Service='" & serviceName & "', AccountSlot='" & accountNameForKeychainSlot & "'). Error: " & errMsg)
		else if "could not be found in the keychain" is in errMsg then
			my logDetail("Keychain item not found (Service='" & serviceName & "', AccountSlot='" & accountNameForKeychainSlot & "'). Error: " & errMsg)
		else
			my logDetail("Error reading from Keychain (Service='" & serviceName & "', AccountSlot='" & accountNameForKeychainSlot & "'): " & errMsg & " (Error " & errNum & ")")
			-- 可以考虑是否在此处显示错误对话框给用户，但可能过于频繁
			-- display dialog "从钥匙串读取登录信息时发生错误：" & return & errMsg buttons {"好的"} default button 1 with icon caution
		end if
		return missing value -- 表示未找到或发生其他读取错误
	end try
end readFromKeychain

