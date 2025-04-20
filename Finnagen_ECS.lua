export type Component = {
	Name: string,
	Entities: {string?},
}

export type ComponentValue = {
	Component: string,
	Value: any,
	Space: {}
}

export type Entity = {
	Name: string,
	Reference: Instance?,
	Space: {},
	
	Components: {ComponentValue?},
	Values: {any}?,
	
	AddComponentValue: (self: Entity, componentName: string, componentValue: any) -> (),
	RemoveComponentValue: (self: Entity, componentName: string) -> (),
	GetComponentFromEntity: (self: Entity, componentName: string) -> Component,
	
	ChangeComponentValue: (self: Entity, componentName: string, newValue: any) -> ()
}

local ecs = {}
ecs.__index = ecs
ecs.Spaces = {}

function ecs.CreateSpace()
	local self = setmetatable({
		Components = {},
		Entities = {}
	}, ecs)
	table.insert(ecs.Spaces, self)
	return self
end

local ecMethods = {}
ecMethods.__index = ecMethods

function ecs:CreateComponent(name: string): Component
	local component: Component = setmetatable({
		Name = name,
		Entities = {},
		Space = self
	}, ecMethods)
	table.insert(self.Components, component)
	 
	return component
end

function ecs:CreateEntity(name: string, reference: Instance?, values: {any?}): Entity
	local entity: Entity = setmetatable({
		Name = name,
		Reference = reference,
		Space = self,
		
		Components = {},
		Values = values
	}, ecMethods)
	table.insert(self.Entities,entity)
	
	if entity.Reference then
		entity.Reference:SetAttribute("LinkedEntity", name)
	end
	
	return entity
end

function ecs.GetLinkedEntity(object: Instance)
	if object:GetAttribute("LinkedEntity") then
		for i, space in ecs.Spaces do
			local entity = ecs.GetEntity(space, object:GetAttribute("LinkedEntity"))
			if entity then
				return entity
			end
		end
	end
	return nil
end

function ecMethods:AddComponentValue(componentName: string, componentValue: any): ()
	local component = ecs.GetComponent(self.Space, componentName)
	if component then
		local componentValue: ComponentValue = setmetatable({
			Component= componentName,
			Value= componentValue
		}, ecMethods)

		table.insert(self.Components, componentValue)
		table.insert(component.Entities, self.Name)
	end
end

function ecMethods:RemoveComponentValue(componentName: string): ()
	local component = ecs.GetComponent(self.Space, componentName)
	local componentValue
	for i, value in self.Components do
		if value.Component == componentName then
			componentValue = value
			break
		end
	end
	
	if component and componentValue then
		table.remove(self.Components, table.find(self.Components, componentValue))
		table.remove(component.Entities, table.find(component.Entities, self.Name))
		
		setmetatable(componentValue, nil)
		componentValue = nil
	end
end

function ecMethods:GetComponentFromEntity(componentName: string): ComponentValue?
	for i, component in self.Components do
		if component.Component == componentName then
			return component
		end
	end
	return nil
end

function ecMethods:ChangeComponentValue(componentName: string, newValue: any): ()
	local componentValue: ComponentValue = self:GetComponentFromEntity(componentName)
	if componentValue then
		if typeof(componentValue.Value) ~= typeof(newValue) then
			warn("Changing value of Entity "..self.Name.."'s '"..componentValue.Component.."' property to value of different type.")
		end
		componentValue.Value = newValue
	end
end

function ecs.GetComponent(space, name: string): Component?
	for i,component in space.Components do
		if component.Name == name then
			return component
		end
	end
	return nil
end

function ecs.GetEntity(space, name: string)
	for i,entity in space.Entities do
		if entity.Name == name then
			return entity
		end
	end
	return nil
end

return ecs