--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
-- luacheck: globals registerMenuItem onMenuSelection onListChanged update getWindows addEntry createWindow
function onInit() registerMenuItem(Interface.getString('list_menu_createitem'), 'insert', 5) end

function onMenuSelection(selection)
	if selection == 5 then self.addEntry(true) end
end

function onListChanged() update() end

function update()
	local bEdit = (window.effects_list_iedit.getValue() == 1)
	for _, w in ipairs(getWindows()) do
		w.idelete.setVisibility(bEdit)
	end
end

function addEntry(bFocus)
	local w = createWindow()
	if w then
		if bFocus then w.name.setFocus() end
	end
	return w
end
