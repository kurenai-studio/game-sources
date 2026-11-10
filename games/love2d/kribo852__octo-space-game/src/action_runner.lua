
-- runs actions, if the result is false (not continue) then that action is removed
local actions = {

}


function actions.add_action(action)
	table.insert(actions, action)
end

function actions.run_actions()
	local removed = {}

	--print("all added actions length "..#actions)

	for i=1,#actions do
		local result_continue_action = actions[i]();

		if not result_continue_action then
			table.insert(removed, i)
		end
	end

	local reverse_removed = actions.reverse(removed)

	for i=1,#reverse_removed do
		table.remove(actions, reverse_removed[i])
	end

end

function actions.reverse(tab)
    for i = 1,math.floor((#tab)/2) do
        tab[i], tab[#tab-i+1] = tab[#tab-i+1], tab[i]
    end
    return tab
end

return actions

