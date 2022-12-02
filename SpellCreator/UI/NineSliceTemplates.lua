---@class ns
local ns = select(2, ...)

local Constants = ns.Constants
local NineSlice = ns.Utils.NineSlice

local ASSETS_PATH = Constants.ASSETS_PATH

local myNineSliceFile_corners = ASSETS_PATH .. "/frame_border_corners"
local myNineSliceFile_vert = ASSETS_PATH .. "/frame_border_vertical"
local myNineSliceFile_horz = ASSETS_PATH .. "/frame_border_horizontal"

NineSlice.AddLayout("ArcanumFrameTemplate", {
	TopLeftCorner = { tex = myNineSliceFile_corners, txl = 0.263672, txr = 0.521484, txt = 0.263672, txb = 0.521484, x = -13, y = 16, }, --0.263672, 0.521484, 0.263672, 0.521484
	--TopRightCorner =  { tex = myNineSliceFile_corners, txl = 0.00195312, txr = 0.259766, txt = 0.263672, txb = 0.521484, x = 4, y = 16,}, -- 0.00195312, 0.259766, 0.263672, 0.521484
	TopRightCorner =  { tex = myNineSliceFile_corners, txl = 0.00195312, txr = 0.259766, txt = 0.525391, txb = 0.783203, x = 4, y = 16, }, -- 0.00195312, 0.259766, 0.525391, 0.783203 -- this is the double button one in the top right corner.
	BottomLeftCorner =  { tex = myNineSliceFile_corners, txl = 0.00195312, txr = 0.259766, txt = 0.00195312, txb = 0.259766, x = -13, y = -3, }, -- 0.00195312, 0.259766, 0.00195312, 0.259766
	BottomRightCorner = { tex = myNineSliceFile_corners, txl = 0.263672, txr = 0.521484, txt = 0.00195312, txb = 0.259766, x = 4, y = -3, }, -- 0.263672, 0.521484, 0.00195312, 0.259766
	TopEdge = { tex = myNineSliceFile_horz, txl = 0, txr = 1, txt = 0.263672, txb = 0.521484, }, -- 0, 1, 0.263672, 0.521484
	BottomEdge = { tex = myNineSliceFile_horz, txl = 0, txr = 1, txt = 0.00195312, txb = 0.259766, }, -- 0, 1, 0.00195312, 0.259766
	LeftEdge = { tex = myNineSliceFile_vert, txl = 0.00195312, txr = 0.259766, txt = 0, txb = 1, }, -- 0.00195312, 0.259766, 0, 1
	RightEdge = { tex = myNineSliceFile_vert, txl = 0.263672, txr = 0.521484, txt = 0, txb = 1, }, -- 0.263672, 0.521484, 0, 1
})

NineSlice.AddLayout("ArcanumFrameTemplateNoPortrait", {
	TopLeftCorner = { tex = myNineSliceFile_corners, txl = 0.525391, txr = 0.783203, txt = 0.00195312, txb = 0.259766, x = -12, y = 16, },
	TopRightCorner =  { tex = myNineSliceFile_corners, txl = 0.00195312, txr = 0.259766, txt = 0.263672, txb = 0.521484, x = 4, y = 16, },
	--TopRightCorner =  { tex = myNineSliceFile_corners, txl = 0.00195312, txr = 0.259766, txt = 0.525391, txb = 0.783203, x = 4, y = 16, }, -- this is the double one
	BottomLeftCorner =  { tex = myNineSliceFile_corners, txl = 0.00195312, txr = 0.259766, txt = 0.00195312, txb = 0.259766, x = -12, y = -3, },
	BottomRightCorner = { tex = myNineSliceFile_corners, txl = 0.263672, txr = 0.521484, txt = 0.00195312, txb = 0.259766, x = 4, y = -3, },
	TopEdge = { tex = myNineSliceFile_horz, txl = 0, txr = 1, txt = 0.263672, txb = 0.521484, tilesHorizontally = true},
	BottomEdge = { tex = myNineSliceFile_horz, txl = 0, txr = 1, txt = 0.00195312, txb = 0.259766, tilesHorizontally = true},
	LeftEdge = { tex = myNineSliceFile_vert, txl = 0.00195312, txr = 0.259766, txt = 0, txb = 1, tilesVertically = true },
	RightEdge = { tex = myNineSliceFile_vert, txl = 0.263672, txr = 0.521484, txt = 0, txb = 1, tilesVertically = true },
})
