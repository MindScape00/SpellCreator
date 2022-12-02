---@class ns
local ns = select(2, ...)

local Constants = ns.Constants

local function GetNineSlicePiece(container, pieceName)
    if container.GetNineSlicePiece then
      local piece = container:GetNineSlicePiece(pieceName);
      if piece then
        return piece, true;
      end
    end

    local piece = container[pieceName];
    if piece then
      return piece, true;
    else
      piece = container:CreateTexture()
      container[pieceName] = piece;
      return piece, false;
    end
end

local function PropagateLayoutSettingsToPieceLayout(userLayout, pieceLayout)
    -- Only apply mirrorLayout if it wasn't explicitly defined
    if pieceLayout.mirrorLayout == nil then
      pieceLayout.mirrorLayout = userLayout.mirrorLayout;
    end

    -- ... and other settings that apply to the whole nine-slice
end

local function SetupTextureCoordinates(piece, setupInfo, pieceLayout)
    local left, right, top, bottom = 0, 1, 0, 1;
    left = pieceLayout.txl or left
    right = pieceLayout.txr or right
    top = pieceLayout.txt or top
    bottom = pieceLayout.txb or bottom

    if pieceLayout.mirrorLayout then
      if setupInfo.mirrorVertical then
        top, bottom = bottom, top;
      end

      if setupInfo.mirrorHorizontal then
        left, right = right, left;
      end
    end

    piece:SetHorizTile(setupInfo.tileHorizontal);
    piece:SetVertTile(setupInfo.tileVertical);
    piece:SetTexCoord(left, right, top, bottom);
end

local function SetupPieceVisuals(piece, setupInfo, pieceLayout)
    --- Change texture coordinates before applying atlas.
    SetupTextureCoordinates(piece, setupInfo, pieceLayout);

    -- textureKit is optional, that's fine; but if it's nil the caller should ensure that there are no format specifiers in .atlas
    --local atlasName = GetFinalNameFromTextureKit(pieceLayout.atlas, textureKit);
    --local info = C_Texture.GetAtlasInfo(atlasName);
    piece:SetHorizTile(pieceLayout and pieceLayout.tilesHorizontally or false);
    piece:SetVertTile(pieceLayout and pieceLayout.tilesVertically or false);
    piece:SetTexture(pieceLayout.tex, true);
end

local function SetupCorner(container, piece, setupInfo, pieceLayout)
    piece:ClearAllPoints();
    piece:SetPoint(pieceLayout.point or setupInfo.point, container, pieceLayout.relativePoint or setupInfo.point, pieceLayout.x, pieceLayout.y);
end

local function SetupEdge(container, piece, setupInfo, pieceLayout)
    piece:ClearAllPoints();
    piece:SetPoint(setupInfo.point, GetNineSlicePiece(container, setupInfo.relativePieces[1]), setupInfo.relativePoint, pieceLayout.x, pieceLayout.y);
    piece:SetPoint(setupInfo.relativePoint, GetNineSlicePiece(container, setupInfo.relativePieces[2]), setupInfo.point, pieceLayout.x1, pieceLayout.y1);
end

local function SetupCenter(container, piece, setupInfo, pieceLayout)
    piece:ClearAllPoints();
    piece:SetPoint("TOPLEFT", GetNineSlicePiece(container, "TopLeftCorner"), "BOTTOMRIGHT", pieceLayout.x, pieceLayout.y);
    piece:SetPoint("BOTTOMRIGHT", GetNineSlicePiece(container, "BottomRightCorner"), "TOPLEFT", pieceLayout.x1, pieceLayout.y1);
end

  -- Defines the order in which each piece should be set up, and how to do the setup.
  --
  -- Mirror types: As a texture memory and effort savings, many borders are assembled from a single topLeft corner, and top/left edges.
  -- That's all that's required if everything is symmetrical (left edge is also superfluous, but allows for more detail variation)
  -- The mirror flags specify which texture coords to flip relative to the piece that would use default texture coordinates: left = 0, top = 0, right = 1, bottom = 1
local nineSliceSetup =
  {
    { pieceName = "TopLeftCorner", point = "TOPLEFT", fn = SetupCorner, },
    { pieceName = "TopRightCorner", point = "TOPRIGHT", mirrorHorizontal = true, fn = SetupCorner, },
    { pieceName = "BottomLeftCorner", point = "BOTTOMLEFT", mirrorVertical = true, fn = SetupCorner, },
    { pieceName = "BottomRightCorner", point = "BOTTOMRIGHT", mirrorHorizontal = true, mirrorVertical = true, fn = SetupCorner, },
    { pieceName = "TopEdge", point = "TOPLEFT", relativePoint = "TOPRIGHT", relativePieces = { "TopLeftCorner", "TopRightCorner" }, fn = SetupEdge, tileHorizontal = true },
    { pieceName = "BottomEdge", point = "BOTTOMLEFT", relativePoint = "BOTTOMRIGHT", relativePieces = { "BottomLeftCorner", "BottomRightCorner" }, mirrorVertical = true, tileHorizontal = true, fn = SetupEdge, },
    { pieceName = "LeftEdge", point = "TOPLEFT", relativePoint = "BOTTOMLEFT", relativePieces = { "TopLeftCorner", "BottomLeftCorner" }, tileVertical = true, fn = SetupEdge, },
    { pieceName = "RightEdge", point = "TOPRIGHT", relativePoint = "BOTTOMRIGHT", relativePieces = { "TopRightCorner", "BottomRightCorner" }, mirrorHorizontal = true, tileVertical = true, fn = SetupEdge, },
    { pieceName = "Center", fn = SetupCenter, },
  };

local layouts =
  {
    PortraitFrameTemplate =
    {
      TopLeftCorner = { layer = "OVERLAY", atlas = "UI-Frame-PortraitMetal-CornerTopLeft", x = -13, y = 16, },
      TopRightCorner =  { layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerTopRight", x = 4, y = 16, },
      BottomLeftCorner =  { layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerBottomLeft", x = -13, y = -3, },
      BottomRightCorner = { layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerBottomRight", x = 4, y = -3, },
      TopEdge = { layer="OVERLAY", atlas = "_UI-Frame-Metal-EdgeTop", x = 0, y = 0, x1 = 0, y1 = 0, },
      BottomEdge = { layer = "OVERLAY", atlas = "_UI-Frame-Metal-EdgeBottom", x = 0, y = 0, x1 = 0, y1 = 0, },
      LeftEdge = { layer = "OVERLAY", atlas = "!UI-Frame-Metal-EdgeLeft", x = 0, y = 0, x1 = 0, y1 = 0 },
      RightEdge = { layer = "OVERLAY", atlas = "!UI-Frame-Metal-EdgeRight", x = 0, y = 0, x1 = 0, y1 = 0, },
    },

    ButtonFrameTemplateNoPortrait =
    {
      TopLeftCorner = { layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerTopLeft", x = -12, y = 16, },
      TopRightCorner =  { layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerTopRight", x = 4, y = 16, },
      BottomLeftCorner =  { layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerBottomLeft", x = -12, y = -3, },
      BottomRightCorner = { layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerBottomRight", x = 4, y = -3, },
      TopEdge = { layer = "OVERLAY", atlas = "_UI-Frame-Metal-EdgeTop", },
      BottomEdge = { layer = "OVERLAY", atlas = "_UI-Frame-Metal-EdgeBottom", },
      LeftEdge = { layer = "OVERLAY", atlas = "!UI-Frame-Metal-EdgeLeft", },
      RightEdge = { layer = "OVERLAY", atlas = "!UI-Frame-Metal-EdgeRight", },
    },

    --[[
    ArcanumFrameTemplate =
    {
        TopLeftCorner = { tex = myNineSliceFile_corners, txl = 0.263672, txr = 0.521484, txt = 0.263672, txb = 0.521484, }, --0.263672, 0.521484, 0.263672, 0.521484
        TopRightCorner =  { tex = myNineSliceFile_corners, txl = 0.00195312, txr = 0.259766, txt = 0.525391, txb = 0.783203, }, -- 0.00195312, 0.259766, 0.525391, 0.783203 -- this is the double button one in the top right corner.
        BottomLeftCorner =  { tex = myNineSliceFile_corners, txl = 0.00195312, txr = 0.259766, txt = 0.00195312, txb = 0.259766, }, -- 0.00195312, 0.259766, 0.00195312, 0.259766
        BottomRightCorner = { tex = myNineSliceFile_corners, txl = 0.263672, txr = 0.521484, txt = 0.00195312, txb = 0.259766, }, -- 0.263672, 0.521484, 0.00195312, 0.259766
        TopEdge = { tex = myNineSliceFile_horz, txl = 0, txr = 1, txt = 0.263672, txb = 0.521484, }, -- 0, 1, 0.263672, 0.521484
        BottomEdge = { tex = myNineSliceFile_horz, txl = 0, txr = 1, txt = 0.00195312, txb = 0.259766, }, -- 0, 1, 0.00195312, 0.259766
        LeftEdge = { tex = myNineSliceFile_vert, txl = 0.00195312, txr = 0.259766, txt = 0, txb = 1, }, -- 0.00195312, 0.259766, 0, 1
        RightEdge = { tex = myNineSliceFile_vert, txl = 0.263672, txr = 0.521484, txt = 0, txb = 1, }, -- 0.263672, 0.521484, 0, 1
    },

    ArcanumFrameTemplateNoPortrait =
    {
        TopLeftCorner = { tex = myNineSliceFile_corners, txl = 0.525391, txr = 0.783203, txt = 0.00195312, txb = 0.259766, }, --0.525391, 0.783203, 0.00195312, 0.259766
        TopRightCorner =  { tex = myNineSliceFile_corners, txl = 0.00195312, txr = 0.259766, txt = 0.263672, txb = 0.521484, }, -- 0.00195312, 0.259766, 0.263672, 0.521484 -- the single button one
        BottomLeftCorner =  { tex = myNineSliceFile_corners, txl = 0.00195312, txr = 0.259766, txt = 0.00195312, txb = 0.259766, }, -- 0.00195312, 0.259766, 0.00195312, 0.259766
        BottomRightCorner = { tex = myNineSliceFile_corners, txl = 0.263672, txr = 0.521484, txt = 0.00195312, txb = 0.259766, }, -- 0.263672, 0.521484, 0.00195312, 0.259766
        TopEdge = { tex = myNineSliceFile_horz, txl = 0, txr = 1, txt = 0.263672, txb = 0.521484, }, -- 0, 1, 0.263672, 0.521484
        BottomEdge = { tex = myNineSliceFile_horz, txl = 0, txr = 1, txt = 0.00195312, txb = 0.259766, }, -- 0, 1, 0.00195312, 0.259766
        LeftEdge = { tex = myNineSliceFile_vert, txl = 0.00195312, txr = 0.259766, txt = 0, txb = 1, }, -- 0.00195312, 0.259766, 0, 1
        RightEdge = { tex = myNineSliceFile_vert, txl = 0.263672, txr = 0.521484, txt = 0, txb = 1, }, -- 0.263672, 0.521484, 0, 1
    },
    --]]
  }

  --------------------------------------------------
  -- NINE SLICE UTILS

local function ApplyLayoutFromTex(container, userLayout)
    for pieceIndex, setup in ipairs(nineSliceSetup) do
      local pieceName = setup.pieceName;
      local pieceLayout = userLayout[pieceName];
      if pieceLayout then
        PropagateLayoutSettingsToPieceLayout(userLayout, pieceLayout);

        local piece, pieceAlreadyExisted = GetNineSlicePiece(container, pieceName);
        if not pieceAlreadyExisted then
          container[pieceName] = piece;
          piece:SetDrawLayer(pieceLayout.layer or "BORDER", pieceLayout.subLevel);
        end

        -- Piece setup can change arbitrary properties, do it before changing the texture.
        setup.fn(container, piece, setup, pieceLayout);
        SetupPieceVisuals(piece, setup, pieceLayout);
      end
    end
  end

local function GetLayout(layoutName)
    return layouts[layoutName];
end

local function ApplyLayoutByName(container, userLayoutName)
    return ApplyLayoutFromTex(container, GetLayout(userLayoutName));
end

local function AddLayout(layoutName, layout)
    layouts[layoutName] = layout;
end

---@class Utils_NineSlice
ns.Utils.NineSlice = {
    ApplyLayoutFromTex = ApplyLayoutFromTex,
    ApplyLayoutByName = ApplyLayoutByName,
    AddLayout = AddLayout,
}
