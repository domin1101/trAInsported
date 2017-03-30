
INDIVIDUALS_NUMBER = 8
PARAMETER_NUMBER = 3
MATCH_SIZE = 1

matchIndividuals = {}
currentLevel = {}
nextLevel = {}
individualIndex = 1
levelNo = 1
evolution = {}
nextId = 1
parameterStart = {[1]=0.2, [2]=1, [3]=1 }
matchesPerIndividual = 10

function swap(array, index1, index2)
    array[index1], array[index2] = array[index2], array[index1]
end

function shuffle(array)
    local counter = #array
    while counter > 1 do
        local index = math.random(counter)
        swap(array, index, counter)
        counter = counter - 1
    end
end

function evolution.initialize()
	individuals = {}
	mutationStrengthChangeSpeed = 1.6
	mutationStrengthMax = 50
	mutationStrengthMin = 0.000001
	local text = ""
	for i=1,INDIVIDUALS_NUMBER do
		individuals[i] = {["id"]=nextId,["parameters"]={},["mutationStrength"]={},["fitness"]=0}
		nextId = nextId + 1
		for r=1,PARAMETER_NUMBER do
			individuals[i].parameters[r] = 0.5 -- math.random() -- parameterStart[r]
			individuals[i].mutationStrength[r] = 0.2
			text = text .. " " .. individuals[i].parameters[r]
		end
	end
	print("Parameters:", text)
	evolution.initializeTournament()
end

function evolution.initializeTournament()
	print("Starting new tournament")
	for i = 1,INDIVIDUALS_NUMBER do
		individuals[i].fitness = 0
		individuals[i].subFitness = 0
		nextLevel[i] = individuals[i]
	end
	levelNo = -1
	evolution.nextLevel()
end

function evolution.nextLevel()
	levelNo = levelNo + 1
	print("Starting next Level", levelNo)
	currentLevel = nextLevel
	nextLevel = {}
	shuffle(currentLevel)
	individualIndex = 1
end

function evolution.determineNextMatch()
	local text = ""
	for i = 1,MATCH_SIZE do
		matchIndividuals[i] = currentLevel[math.floor((individualIndex - 1) / matchesPerIndividual) + 1]
		individualIndex = individualIndex + 1
		text = text .. " " .. matchIndividuals[i].id
		if individualIndex > #currentLevel * matchesPerIndividual then
			break
		end
	end
	if (individualIndex - 2) % matchesPerIndividual == 0 then
		print("Next match:", text)
	end
end

function evolution.processMatchResults()
	for i = 1,#aiList do
		aiList[i].id = i
	end
	table.sort(aiList, function(a,b) return a.points > b.points end)
	local text = ""
	for i = 1,#aiList do
		if aiList[i].id == 1 then
			matchIndividuals[1].fitness = matchIndividuals[1].fitness + i
			matchIndividuals[1].subFitness = matchIndividuals[1].subFitness + aiStats[1].pTransported
			text = text .. " " .. matchIndividuals[1].id .. " " .. matchIndividuals[1].fitness .. "(" .. matchIndividuals[1].subFitness .. ")"
		end
	end
	if (individualIndex - 1) % matchesPerIndividual == 0 then
		print("Result:", text)
	end
end

function evolution.individualById(id)
	for i = 1,INDIVIDUALS_NUMBER do
		if individuals[i].id == id then
			return individuals[i]
		end
	end
	return nil
end

function evolution.reuse(number)
	for i=1,number do
		table.insert(newIndividuals, individuals[i])
	end
end

function evolution.mutate()
	for i = 1,3 do
		for n = 1,4-i do
			newIndividual = {["id"]=nextId,["parameters"]={},["mutationStrength"]={},["fitness"]=0}
			nextId = nextId + 1
			for r=1,PARAMETER_NUMBER do
				newIndividual.mutationStrength[r] = individuals[i].mutationStrength[r] * math.exp(mutationStrengthChangeSpeed * ndist:sample(rng))
				newIndividual.mutationStrength[r] = math.sign(newIndividual.mutationStrength[r]) * math.min(mutationStrengthMax, math.max(mutationStrengthMin, math.abs(newIndividual.mutationStrength[r])));
				newIndividual.parameters[r] = individuals[i].parameters[r] + newIndividual.mutationStrength[r] * ndist:sample(rng)
			end
			table.insert(newIndividuals, newIndividual)
		end
	end
end

function evolution.create(number)
	for i = 1,number do
		newIndividual = {["id"]=nextId,["parameters"]={},["mutationStrength"]={},["fitness"]=0}
		for r=1,PARAMETER_NUMBER do
			newIndividual.parameters[r] = math.random()
			newIndividual.mutationStrength[r] = 0.2
		end
		table.insert(newIndividuals, newIndividual)
	end
end


function evolution.doEvolution()
	newIndividuals = {}
	table.sort(individuals, function(a,b) return a.fitness < b.fitness or (a.fitness == b.fitness and a.subFitness > b.subFitness) end)
	evolution.reuse(1)
	evolution.mutate()
	evolution.create(1)
	individuals = newIndividuals
	for i = 1,#individuals do
		individuals[i].fitness = 0
	end
	evolution.printGeneration()
end

function evolution.printGeneration()
	ids = ""
	param = ""
	strength = ""
	for i=1,#individuals do
		ids = ids .. " " .. individuals[i].id
		param = param .. " [ "
		strength = strength .. " [ "
		for r=1,PARAMETER_NUMBER do
			param = param .. " " .. individuals[i].parameters[r]
			strength = strength .. " " .. individuals[i].mutationStrength[r]
		end
		param = param .. " ] "
		strength = strength .. " ] "
	end
	print(ids)
	print(param)
	print(strength)
end

function evolution.prepareNextMatch()

	if individuals == nil then
		evolution.initialize()
	else
		evolution.processMatchResults()
	end

	if individualIndex > #currentLevel * matchesPerIndividual then
		if true or #nextLevel < MATCH_SIZE then
			print("Tournament has finished")
			evolution.doEvolution()
			evolution.initializeTournament()
			--os.exit()
		else
			evolution.nextLevel()
		end
	end

	evolution.determineNextMatch()
end

return evolution