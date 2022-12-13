---@class HeaderActionTypeData: ActionTypeDataBase
---@field type "header"
---@field name string

---@class MenuActionTypeData: ActionTypeDataBase
---@field type "submenu"
---@field name string
---@field menuDataLis? ActionType[]

---@class SpacerActionTypeData: ActionTypeDataBase
---@field type "spacer"

---@class ActionTypeDataBase
---@field name string
---@field command string | function
---@field dataName? string
---@field selfAble boolean
---@field inputDescription string
---@field dependency string | nil
---@field doNotDelimit boolean

---@class FunctionActionTypeData: ActionTypeDataBase
---@field command function
---@field comTarget "func"
---@field example string?
---@field revert function | nil
---@field revertDesc string?
---@field revertAlternative string?

---@class ServerActionTypeData: ActionTypeDataBase
---@field command string
---@field comTarget "server"
---@field example string?
---@field revert string | nil
---@field revertDesc string?
---@field revertAlternative string?
