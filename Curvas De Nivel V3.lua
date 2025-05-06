-- Author: XanduGamer
-- Name: Gerador de curvas de nivel v3
-- Description: Gera curvas de nível elevando o terreno e pintando
-- Icon:
-- Hide: no
-- AlwaysLoaded: no

CurvasDeNivel = {}

-- Inicialize as configurações
CurvasDeNivel.settings = {
    depth = 0.06, -- altura da elevação
    curveWidth = 1.2, -- largura da curva (passos laterais)
}

-- Terreno
local terrain = getChild(getRootNode(), "terrain")
if terrain == 0 then
    print("Terreno não encontrado!")
    return
end

-- Criação da UI
function CurvasDeNivel.createUI()
    local WINDOW_WIDTH = 500
    local frameRowSizer = UIRowLayoutSizer.new()
    local window = UIWindow.new(frameRowSizer, "FS25 - CURVAS DE NÍVEL - Ajuste de Altura - by XanduGamer")

    local borderSizer = UIRowLayoutSizer.new()
    UIPanel.new(frameRowSizer, borderSizer, -1, -1, -1, -1, BorderDirection.NONE, 0, 1)
    local rowSizer = UIRowLayoutSizer.new()
    UIPanel.new(borderSizer, rowSizer, -1, -1, WINDOW_WIDTH, 150, BorderDirection.ALL, 10, 1)

    -- Slider de altura
    local sliderPanel = UIGridSizer.new(1, 2, 2, 2)
    UIPanel.new(frameRowSizer, sliderPanel, -1, -1, -1, -1, BorderDirection.ALL, 5)
    UILabel.new(sliderPanel, "Altura da elevação (10cm a 100cm):", false, TextAlignment.TOP, VerticalAlignment.TOP)
    local slider = UIFloatSlider.new(sliderPanel, 0.01, 0.01, 0.20, CurvasDeNivel.settings.depth)
    slider:setOnChangeCallback(function()
        CurvasDeNivel.settings.depth = slider:getValue()
    end)

    -- Slider de largura
    local widthSliderPanel = UIGridSizer.new(1, 2, 2, 2)
    UIPanel.new(frameRowSizer, widthSliderPanel, -1, -1, -1, -1, BorderDirection.ALL, 5)
    UILabel.new(widthSliderPanel, "Largura da curva (0.5 a 2.5):", false, TextAlignment.TOP, VerticalAlignment.TOP)
    local widthSlider = UIFloatSlider.new(widthSliderPanel, 0.5, 0.5, 2.5, CurvasDeNivel.settings.curveWidth)
    widthSlider:setOnChangeCallback(function()
        CurvasDeNivel.settings.curveWidth = widthSlider:getValue()
    end)

    -- Botão de aplicar
    local button = UIGridSizer.new(1, 1, 2, 2)
    UIPanel.new(frameRowSizer, button, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    UIButton.new(button, "✅ Aplicar curvas", function()
        CurvasDeNivel.setTerrainHeight(CurvasDeNivel.settings.depth, CurvasDeNivel.settings.curveWidth)
    end)

    window:showWindow()
end

function CurvasDeNivel.crossProduct(ax, ay, az, bx, by, bz)
    return ay * bz - az * by, az * bx - ax * bz, ax * by - ay * bx
end

function CurvasDeNivel.setTerrainHeight(mHeightOffset, mSideCount)
    local mTerrainID = getChild(getRootNode(), "terrain")
    if mTerrainID == 0 then
        print("Error: Terrain node not found.")
        return
    end

    if getNumSelected() == 0 then
        print("Error: Selecione uma ou mais splines.")
        return
    end

    local mSplinePiece = 1.0 -- ponto a cada 1 metro

    local mSplineIDs = {}
    for i = 0, getNumSelected() - 1 do
        local mID = getSelection(i)
        table.insert(mSplineIDs, mID)
    end

    for _, mSplineID in pairs(mSplineIDs) do
        local mSplineLength = getSplineLength(mSplineID)
        local mSplinePiecePoint = mSplinePiece / mSplineLength
        local mSplinePos = 0.0

        while mSplinePos <= 1.0 do
            local mPosX, mPosY, mPosZ = getSplinePosition(mSplineID, mSplinePos)
            local mHeight = getTerrainHeightAtWorldPos(mTerrainID, mPosX, 0, mPosZ) + mHeightOffset

            local mDirX, mDirY, mDirZ = worldDirectionToLocal(mSplineID, getSplineDirection(mSplineID, mSplinePos))
            local mVecDx, mVecDy, mVecDz = CurvasDeNivel.crossProduct(mDirX, mDirY, mDirZ, 0, 0.5, 0)

            setTerrainHeightAtWorldPos(mTerrainID, mPosX, mPosY, mPosZ, mHeight)

            -- Otimização de largura
            local spacing = 1.0
            local maxSteps = 10
            local steps = math.min(math.floor(mSideCount / spacing), maxSteps)

            for i = 1, steps do
                local offsetX = i * mVecDx
                local offsetZ = i * mVecDz

                setTerrainHeightAtWorldPos(mTerrainID, mPosX + offsetX, mPosY, mPosZ + offsetZ, mHeight)
                setTerrainHeightAtWorldPos(mTerrainID, mPosX - offsetX, mPosY, mPosZ - offsetZ, mHeight)
            end

            mSplinePos = mSplinePos + mSplinePiecePoint
        end
    end
end

-- Inicia UI
CurvasDeNivel.createUI()
