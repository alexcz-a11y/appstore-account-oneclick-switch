-- Script: �л�AppStore�˺�
-- Version: 2.2.7 (������¼�Ի����ʼ�ȴ�Ϊ1.5s)
-- Author: Cascade AI & USER

-- ȫ����־��¼��
global scriptLog

-- �û��˻���Ϣ (ȷ������׼ȷ)
property account1User : "alexcopd@gmail.com"
property account1Pass : "6954236Tom"
property account2User : "cyjcz0214@gmail.com"
property account2Pass : "Alex6.30Cyj"

-- �˵���ػ��ı� (ʹ������ȷ�������ڴ�������п���)
property menuStoreTextZh : "�̵�"
property menuSignOutTextZh : "�˳���¼"
property menuLoginTextZh : "��¼"

property menuStoreTextEn : "Store"
property menuSignOutTextEn : "Sign Out"
property menuLoginTextEn : "Sign In"

-- ��ִ�п�
on run
	set scriptLog to {} -- ��ʼ���Ƶ��˴�
	my logDetail("========= App Store Account Switcher Script Started (v2.2.7) =========")
	my logDetail("Predefined Account 1: " & account1User)
	my logDetail("Predefined Account 2: " & account2User)
	
	set targetUser to ""
	set targetPass to ""
	
	try
		my logDetail("Displaying account selection dialog to user.")
		display dialog "��ѡ��Ҫ������ App Store �˺ţ�" buttons {"�˺�1", "�˺�2", "���˳���ǰ�˺�"} default button "�˺�1" with title "App Store �˺��л���"
		set dialogResult to result
		set choice to button returned of dialogResult
		my logDetail("User selected: '" & choice & "'.")
		
		if choice is "�˺�1" then
			set targetUser to account1User
			set targetPass to account1Pass
			my logDetail("Target account set to Account 1: " & targetUser)
		else if choice is "�˺�2" then
			set targetUser to account2User
			set targetPass to account2Pass
			my logDetail("Target account set to Account 2: " & targetUser)
		else if choice is "���˳���ǰ�˺�" then
			my logDetail("User chose '���˳���ǰ�˺�'.")
		end if
		
		my logDetail("Step 1: Attempting to sign out from App Store...")
		performSignOut()
		
		if choice is "���˳���ǰ�˺�" then
			my logDetail("Sign-out only operation complete. Script will now finalize.")
			error number -128 -- User cancellation to trigger final log display
		end if
		
		my logDetail("Step 2: Attempting to click the 'Sign In' / '��¼' menu item...")
		set signInClickedSuccessfully to clickSignInMenu()
		
		my logDetail("Step 3: Processing login.")
		if signInClickedSuccessfully then
			my logDetail("Successfully clicked the sign-in menu item. Attempting automatic credential input...")
			set autoInputSuccess to my performAutoLogin(targetUser, targetPass)
			
			if not autoInputSuccess then
				my logDetail("Automatic credential input FAILED or was skipped. Falling back to manual input prompt.")
				display dialog "�Զ������˺�����ʧ�ܻ����App Store ��¼����Ӧ�ѳ��֡����ֶ����������˺���Ϣ��" & return & return & "Apple ID: " & targetUser & return & "����: " & targetPass with title "�ֶ���¼��Ϣ" buttons {"�õ�"} default button "�õ�"
				my logDetail("User acknowledged manual input dialog after auto-input failure.")
			else
				my logDetail("Automatic credential input reported as successful or attempted.")
				display dialog "�ѳ����Զ������˺����롣���� App Store ��¼״̬��" buttons {"�õ�"} default button "�õ�" giving up after 5
				my logDetail("Brief dialog shown after auto-input attempt.")
			end if
		else
			my logDetail("Failed to click the sign-in menu item, or it was not found/enabled.")
			my logDetail("Displaying fallback dialog to guide user for manual sign-in via App Store or System Settings.")
			display dialog "δ���Զ���� App Store �еġ���¼����Sign In��ѡ������ѵ�¼���˵�����ڻ�δ���ã���" & return & return & "���� App Store ���棬����ͨ�� ϵͳ���� > Apple ID > ý���빺����Ŀ �ֶ���¼��" & return & return & "Ŀ���˺���Ϣ:" & return & "Apple ID: " & targetUser with title "������ʾ���ֶ���¼" buttons {"�õ�"} default button "�õ�"
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

-- �������: ִ���˳���¼���� (������v2.1һ�£��˴�ʡ���Լ����ظ�)
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
		display dialog "���Դ� App Store �˳���¼ʱ��������" & return & errMsg & return & "���顰�������ܡ�Ȩ�ޣ����ֶ�������" with title "�˳���������" buttons {"�õ�"} default button 1
		my logDetail("performSignOut handler terminated due to error.")
	end try
	my logDetail("performSignOut handler finished.")
end performSignOut

-- �������: �����¼/Sign In�˵��� (������v2.1һ�£��˴�ʡ���Լ����ظ�)
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

-- �´������: ִ���Զ���¼ (�����˺�����)
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


-- �����������: ��ϸ��־��¼ (��ʱ���) (������v2.1һ�£��˴�ʡ��)
on logDetail(messageText)
	try
		set timestamp to time string of (current date)
		set finalMessage to "[" & timestamp & "] " & messageText
		tell scriptLog to copy finalMessage to its end
	on error
		-- Fallback if logging itself fails
	end try
end logDetail

-- �����������: �ϲ���־�б�Ϊ�ַ��� (������v2.1һ�£��˴�ʡ��)
on joinLogs(logList)
	set prevDelimiters to AppleScript's text item delimiters
	set AppleScript's text item delimiters to return
	set joinedString to logList as string
	set AppleScript's text item delimiters to prevDelimiters
	return joinedString
end joinLogs

-- �����������: �ű�����ʱ�Ĳ��� (��ʾ��־) (������v2.1һ�£��˴�ʡ��)
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

