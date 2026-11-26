//  Eispinguin
//  Copyright (C) 2026 AnatolyStev
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

package editor;

import collision.GroundPiece;
import collision.TerrainManager;
import editor.LevelDocument;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import lime.ui.FileDialog;
import lime.ui.FileDialogType;
import openfl.Assets;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import states.PlayState;
import util.GroundPieceDefinition;

class LevelEditorState extends FlxState
{
    static inline var resizeStep:Int = 256;
    static inline var minLevelSize:Int = 800;
    static inline var minLevelHeight:Int = 600;
    static inline var maxLevelSize:Int = 16384; // 8192 * 2

    static inline var cameraSpeed:Float = 500;

    public var levelAssetPath:String;
    public var savePath:String;

    var initialJson:Null<String>;

    var fileDialog:FileDialog;

    var currentFilePath:Null<String> = null;

    var document:LevelDocument;

    var groundpieceLibrary:GroundPieceLibrary;
    var musicLibrary:MusicLibrary;

    var history:EditorHistory;

    var terrain:TerrainManager;

    var playerMarker:FlxSprite;
    var selectionOutline:FlxSprite;

    var hud:FlxText;

    var tool:String = "place";

    var selectedPieceIndex:Int = 0;
    var selectedPlacementIndex:Int = -1;
    var selectedMusicIndex:Int = 0;

    var draggingPiece:Bool = false;
    var draggingPlayer:Bool = false;
    var dragPreview:FlxSprite;

    var dragStartX:Int = 0;
    var dragStartY:Int = 0;

    var dragTargetX:Int = 0;
    var dragTargetY:Int = 0;

    var dragOffsetX:Float = 0;
    var dragOffsetY:Float = 0;

    var dragChanged:Bool = false;

    var levelGradient:FlxSprite;

    var displayedGradientTop:String = "";
    var displayedGradientBottom:String = "";

    var objectLibrary:LevelObjectLibrary;

    var selectedObjectIndex:Int = 0;
    var selectedObjectPlacementIndex:Int = -1;

    var objectSprites:Array<FlxSprite> = [];

    var draggingObject:Bool = false;

    static inline var sidebarWidth:Int = 210;
    static inline var paletteTileSize:Int = 62;

    var paletteMode:String = "ground";
    var palettePage:Int = 0;
    var sidebarX:Int = 0;

    var toolIconPaths:Array<String> = ["assets/images/engine/editor/paintbrush.png", "assets/images/engine/editor/select.png", "assets/images/engine/editor/select-player.png", "assets/images/engine/editor/object.png"];

    var toolButtonModes:Array<String> = ["place", "select", "player", "object"];
    var toolButtonRects:Array<Rectangle> = [];
    var toolButtonBackgrounds:Array<FlxSprite> = [];

    var actionButtonRects:Array<Rectangle> = [];
    var actionButtonActions:Array<String> = [];

    var paletteTileRects:Array<Rectangle> = [];
    var paletteTileIndices:Array<Int> = [];
    var paletteTileSprites:Array<FlxSprite> = [];

    var groundTabBackground:FlxSprite;
    var objectTabBackground:FlxSprite;

    var musicLabel:FlxText;

    public function new(levelAssetPath:String, savePath:String, ?initialJson:String, ?existingHistory:EditorHistory, ?currentFilePath:String)
    {
        super();

        this.levelAssetPath = levelAssetPath;
        this.savePath = savePath;

        this.initialJson = initialJson;
        this.history = existingHistory;

        this.currentFilePath = currentFilePath;
    }

    override public function create()
    {
        super.create();

        FlxG.mouse.visible = true;

        FlxG.camera.scroll.set(0, 0);

        groundpieceLibrary = GroundPieceLibrary.load("assets/data/groundpieces.json");
        musicLibrary = MusicLibrary.load("assets/data/music.json");
        objectLibrary = LevelObjectLibrary.load("assets/data/objects.json");

        var json = initialJson != null ? initialJson : Assets.getText(levelAssetPath);

        document = LevelDocument.fromJson(json);

        if (history == null)
        {
            history = new EditorHistory();
            history.reset(document.toJson());
        }

        selectedMusicIndex = musicLibrary.findOrAdd(document.music);

        terrain = new TerrainManager(document.width, document.height);

        rebuildTerrain();

        add(terrain.sprite);

        updateLevelGradient();

        dragPreview = new FlxSprite();

        dragPreview.alpha = 0.5;
        dragPreview.visible = false;

        add(dragPreview);

        rebuildObjects();

        playerMarker = new FlxSprite();
        playerMarker.loadGraphic("assets/images/engine/editor/player.png");

        add(playerMarker);

        selectionOutline = new FlxSprite();
        selectionOutline.visible = false;

        add(selectionOutline);

        hud = new FlxText(FlxG.width * 0.5, 8, FlxG.width - sidebarWidth - 165, "", 10);
        hud.scrollFactor.set(0, 0);
        add(hud);

        createEditorGUI();

        updatePlayerMarker();
        refreshSelection();
        updateUnifiedPalette();
        updateHUD();

        updateCameraBounds();

        previewMusic();
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        if (handleKeyboard(elapsed))
        {
            return;
        }

        var guiConsumed = handleGUIInput();

        if (guiConsumed && !draggingPiece && !draggingPlayer && !draggingObject)
        {
            updateHUD();
            return;
        }

        handleMouse();

        updateHUD();
    }

    function handleKeyboard(elapsed:Float):Bool
    {
        if (FlxG.keys.pressed.CONTROL && FlxG.keys.pressed.SHIFT)
        {
            if (FlxG.keys.justPressed.LEFT)
            {
                resizeLevel(-resizeStep, 0);
                return true;
            }

            if (FlxG.keys.justPressed.RIGHT)
            {
                resizeLevel(resizeStep, 0);
                return true;
            }

            if (FlxG.keys.justPressed.UP)
            {
                resizeLevel(0, -resizeStep);
                return true;
            }

            if (FlxG.keys.justPressed.DOWN)
            {
                resizeLevel(0, resizeStep);
                return true;
            }
        }

        if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Z)
        {
            undo();
            return true;
        }

        if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Y)
        {
            redo();
            return true;
        }

        if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.O)
        {
            openLevelDialog();
            return true;
        }

        if (FlxG.keys.pressed.CONTROL && FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.S)
        {
            saveAsDialog();
            return true;
        }

        if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.S)
        {
            save();
            return true;
        }

        if (FlxG.keys.justPressed.ONE)
        {
            setTool("place");
        }

        if (FlxG.keys.justPressed.TWO)
        {
            setTool("select");
        }

        if (FlxG.keys.justPressed.THREE)
        {
            setTool("player");
        }

        if (FlxG.keys.justPressed.FOUR)
        {
            setTool("object");
        }

        if (FlxG.keys.justPressed.Q)
        {
            cycleGroundpiece(-1);
        }

        if (FlxG.keys.justPressed.E)
        {
            cycleGroundpiece(1);
        }

        if (FlxG.keys.justPressed.Z)
        {
            cycleObject(-1);
        }

        if (FlxG.keys.justPressed.X)
        {
            cycleObject(1);
        }

        if (FlxG.keys.justPressed.DELETE)
        {
            deleteSelected();
        }

        if (FlxG.keys.justPressed.PAGEUP)
        {
            cycleMusic(-1);
        }

        if (FlxG.keys.justPressed.PAGEDOWN)
        {
            cycleMusic(1);
        }

        if (FlxG.keys.justPressed.O)
        {
            moveSelectedGroundpieceLayer(-1);
        }

        if (FlxG.keys.justPressed.P)
        {
            moveSelectedGroundpieceLayer(1);
        }

        updateCamera(elapsed);

        return false;
    }

    function updateCameraBounds()
    {
        var canvasWidth = FlxG.width - sidebarWidth;

        var maxX = Math.max(0, document.width - canvasWidth);
        var maxY = Math.max(0, document.height - FlxG.camera.viewHeight);

        FlxG.camera.scroll.x = Math.max(0, Math.min(FlxG.camera.scroll.x, maxX));
        FlxG.camera.scroll.y = Math.max(0, Math.min(FlxG.camera.scroll.y, maxY));
    }

    function moveSelectedGroundpieceLayer(direction:Int):Void
    {
        if (selectedPlacementIndex < 0 || selectedPlacementIndex >= document.pieces.length)
        {
            return;
        }

        var oldIndex = selectedPlacementIndex;
        var newIndex = oldIndex + direction;

        if (newIndex < 0 || newIndex >= document.pieces.length)
        {
            return;
        }

        var placement = document.pieces.splice(oldIndex, 1)[0];

        document.pieces.insert(newIndex, placement);
        selectedPlacementIndex = newIndex;

        commitEdit();
    }

    function updateCamera(elapsed:Float)
    {
        var dx:Float = 0;
        var dy:Float = 0;

        if (FlxG.keys.pressed.LEFT)
        {
            dx -= 1;
        }

        if (FlxG.keys.pressed.RIGHT)
        {
            dx += 1;
        }

        if (FlxG.keys.pressed.UP)
        {
            dy -= 1;
        }

        if (FlxG.keys.pressed.DOWN)
        {
            dy += 1;
        }

        var speed = cameraSpeed;

        if (FlxG.keys.pressed.SHIFT)
        {
            speed *= 2;
        }

        FlxG.camera.scroll.x += dx * speed * elapsed;
        FlxG.camera.scroll.y += dy * speed * elapsed;

        updateCameraBounds();
    }

    function resizeLevel(deltaWidth:Int, deltaHeight:Int)
    {
        var requestedHeight = document.height + deltaHeight;

        if (deltaHeight < 0 && requestedHeight < minLevelHeight)
        {
            trace("Levels can't be shorter than " + minLevelHeight + " pixels!");
            
            return;
        }

        var newWidth = Std.int(Math.max(minLevelSize, Math.min(maxLevelSize, document.width + deltaWidth)));
        var newHeight = Std.int(Math.max(minLevelHeight, Math.min(maxLevelSize, requestedHeight)));

        if (newWidth == document.width && newHeight == document.height)
        {
            return;
        }

        document.width = newWidth;
        document.height = newHeight;

        syncTerrainToDocument();

        history.push(document.toJson());

        updateHUD();
    }

    function syncTerrainToDocument()
    {
        updateLevelGradient();

        if (terrain.width != document.width || terrain.height != document.height)
        {
            var oldSprite = terrain.sprite;
            var terrainIndex = members.indexOf(oldSprite);

            remove(oldSprite, true);
            terrain.destroy();

            terrain = new TerrainManager(document.width, document.height);

            if (terrainIndex < 0)
            {
                terrainIndex = 0;
            }

            insert(terrainIndex, terrain.sprite);
        }

        rebuildTerrain();
        rebuildObjects();
        updateCameraBounds();
    }

    function handleMouse():Void
    {
        var mx = Std.int(Math.floor(FlxG.mouse.x));
        var my = Std.int(Math.floor(FlxG.mouse.y));

        if (FlxG.mouse.justPressed)
        {
            if (mouseOverEditorGUI())
            {
                return;
            }

            switch (tool)
            {
                case "place":
                    placeGroundpiece(mx, my);

                case "select":
                    if (selectObject(mx, my))
                    {
                        startObjectDrag(mx, my);
                    }
                    else
                    {
                        selectGroundpiece(mx, my);

                        if (selectedPlacementIndex >= 0)
                        {
                            var placement = document.pieces[selectedPlacementIndex];
                            var definition = groundpieceLibrary.getById(placement.id);

                            dragStartX = placement.x;
                            dragStartY = placement.y;

                            dragTargetX = placement.x;
                            dragTargetY = placement.y;

                            dragOffsetX = mx - placement.x;
                            dragOffsetY = my - placement.y;

                            draggingPiece = true;
                            dragChanged = false;

                            dragPreview.loadGraphic(definition.bitmap, false, 0, 0, true);

                            dragPreview.alpha = 0.5;
                            dragPreview.x = placement.x;
                            dragPreview.y = placement.y;
                            dragPreview.visible = true;
                        }
                    }

                case "player":
                    draggingPlayer = true;
                    dragChanged = false;

                    dragOffsetX = playerMarker.width / 2;
                    dragOffsetY = playerMarker.height / 2;

                    updatePlayerDrag(mx, my);
                
                case "object":
                    placeObject(mx, my);
            }
        }

        if (FlxG.mouse.pressed)
        {
            if (draggingPiece)
            {
                updatePieceDrag(mx, my);
            }

            if (draggingPlayer)
            {
                updatePlayerDrag(mx, my);
            }

            if (draggingObject)
            {
                updateObjectDrag(mx, my);
            }
        }

        if (FlxG.mouse.justReleased)
        {
            if (draggingPiece)
            {
                updatePieceDrag(mx, my);

                finishPieceDrag();
            }

            if (draggingPlayer)
            {
                updatePlayerDrag(mx, my);

                draggingPlayer = false;

                if (dragChanged)
                {
                    commitEdit(false);
                }
            }

            if (draggingObject)
            {
                updateObjectDrag(mx, my);
                finishObjectDrag();
            }
        }
    }

    function placeGroundpiece(x:Int, y:Int)
    {
        if (groundpieceLibrary.definitions.length == 0)
        {
            return;
        }

        var definition = groundpieceLibrary.definitions[selectedPieceIndex];

        document.pieces.push(new LevelPiecePlacement(definition.id, x, y));

        selectedObjectPlacementIndex = -1;
        selectedPlacementIndex = document.pieces.length - 1;

        terrain.addPiece(new GroundPiece(definition.bitmap, x, y, definition.type, definition.collisionMask));

        commitEdit(false);
    }

    function placeObject(x:Int, y:Int)
    {
        if (objectLibrary.definitions.length == 0)
        {
            return;
        }

        var definition = objectLibrary.definitions[selectedObjectIndex];

        document.objects.push(new ObjectPlacement(definition.id, x, y));

        selectedObjectPlacementIndex = document.objects.length - 1;
        selectedPlacementIndex = -1;

        rebuildObjects();
        commitEdit(false);
    }

    function selectGroundpiece(x:Int, y:Int)
    {
        selectedPlacementIndex = -1;
        selectedObjectPlacementIndex = -1;

        for (i in 0...document.pieces.length)
        {
            var index = document.pieces.length - 1 - i;

            var placement = document.pieces[index];

            var definition = groundpieceLibrary.getById(placement.id);

            var localX = x - placement.x;
            var localY = y - placement.y;

            if (localX < 0 || localY < 0 || localX >= definition.bitmap.width || localY >= definition.bitmap.height)
            {
                continue;
            }

            var pixel = definition.bitmap.getPixel32(localX, localY);
            var alpha = (pixel >>> 24) & 0xFF;

            if (alpha > 0)
            {
                selectedPlacementIndex = index;
                break;
            }
        }

        refreshSelection();
    }

    function selectObject(x:Int, y:Int):Bool
    {
        selectedObjectPlacementIndex = -1;
        selectedPlacementIndex = -1;

        for (i in 0...document.objects.length)
        {
            var index = document.objects.length - 1 - i;
            var placement = document.objects[index];
            var definition = objectLibrary.getById(placement.id);

            var localX = x - placement.x;
            var localY = y - placement.y;

            if (localX < 0 || localY < 0 || localX >= definition.bitmap.width || localY >= definition.bitmap.height)
            {
                continue;
            }

            var pixel = definition.bitmap.getPixel32(localX, localY);
            var alpha = (pixel >>> 24) & 0xFF;

            if (alpha > 0)
            {
                selectedObjectPlacementIndex = index;
                break;
            }
        }

        refreshSelection();

        return selectedObjectPlacementIndex >= 0;
    }

    function updatePieceDrag(mouseX:Int, mouseY:Int)
    {
        if (selectedPlacementIndex < 0 || selectedPlacementIndex >= document.pieces.length)
        {
            return;
        }

        var newX = Std.int(Math.floor(mouseX - dragOffsetX));
        var newY = Std.int(Math.floor(mouseY - dragOffsetY));

        dragTargetX = newX;
        dragTargetY = newY;

        dragChanged = dragTargetX != dragStartX || dragTargetY != dragStartY;

        dragPreview.x = dragTargetX;
        dragPreview.y = dragTargetY;

        selectionOutline.x = dragTargetX;
        selectionOutline.y = dragTargetY;
    }

    function updatePlayerDrag(mouseX:Int, mouseY:Int)
    {
        var newX = Math.floor(mouseX - dragOffsetX);
        var newY = Math.floor(mouseY - dragOffsetY);

        if (document.playerX == newX && document.playerY == newY)
        {
            return;
        }

        document.playerX = newX;
        document.playerY = newY;

        dragChanged = true;

        updatePlayerMarker();
    }

    function startObjectDrag(mouseX:Int, mouseY:Int)
    {
        var placement = document.objects[selectedObjectPlacementIndex];
        var definition = objectLibrary.getById(placement.id);

        dragStartX = placement.x;
        dragStartY = placement.y;

        dragTargetX = placement.x;
        dragTargetY = placement.y;

        dragOffsetX = mouseX - placement.x;
        dragOffsetY = mouseY - placement.y;

        draggingObject = true;
        dragChanged = false;

        dragPreview.loadGraphic(definition.bitmap, false, 0, 0, true);

        dragPreview.alpha = 0.5;
        dragPreview.x = placement.x;
        dragPreview.y = placement.y;
        dragPreview.visible = true;

        if (selectedObjectPlacementIndex < objectSprites.length)
        {
            objectSprites[selectedObjectPlacementIndex].visible = false;
        }
    }

    function updateObjectDrag(mouseX:Int, mouseY:Int)
    {
        if (selectedObjectPlacementIndex < 0 || selectedObjectPlacementIndex >= document.objects.length)
        {
            return;
        }

        var newX = Std.int(Math.floor(mouseX - dragOffsetX));
        var newY = Std.int(Math.floor(mouseY - dragOffsetY));

        dragTargetX = newX;
        dragTargetY = newY;

        dragChanged = dragTargetX != dragStartX || dragTargetY != dragStartY;

        dragPreview.x = dragTargetX;
        dragPreview.y = dragTargetY;

        selectionOutline.x = dragTargetX;
        selectionOutline.y = dragTargetY;
    }

    function finishObjectDrag()
    {
        draggingObject = false;
        dragPreview.visible = false;

        if (!dragChanged)
        {
            if (selectedObjectPlacementIndex >= 0 && selectedObjectPlacementIndex < objectSprites.length)
            {
                objectSprites[selectedObjectPlacementIndex].visible = true;
            }

            updateSelectionPosition();
            return;
        }

        if (selectedObjectPlacementIndex < 0 || selectedObjectPlacementIndex >= document.objects.length)
        {
            return;
        }

        var placement = document.objects[selectedObjectPlacementIndex];

        placement.x = dragTargetX;
        placement.y = dragTargetY;

        rebuildObjects();

        commitEdit(false);

        dragChanged = false;
    }

    function updatePlayerMarker()
    {
        playerMarker.x = document.playerX;
        playerMarker.y = document.playerY;
    }

    function deleteSelected()
    {
        if (selectedObjectPlacementIndex >= 0 && selectedObjectPlacementIndex < document.objects.length)
        {
            document.objects.splice(selectedObjectPlacementIndex, 1);

            selectedObjectPlacementIndex = -1;
            selectedPlacementIndex = -1;

            rebuildObjects();
            commitEdit(false);

            return;
        }

        if (selectedPlacementIndex >= 0 && selectedPlacementIndex < document.pieces.length)
        {
            var index = selectedPlacementIndex;

            if (!terrain.removePiece(index))
            {
                return;
            }

            document.pieces.splice(index, 1);

            selectedPlacementIndex = -1;
            selectedObjectPlacementIndex = -1;

            commitEdit(false);
        }
    }

    function setTool(newTool:String)
    {
        tool = newTool;

        draggingPiece = false;
        draggingPlayer = false;
        draggingObject = false;

        updateToolButtons();
        updateHUD();
    }

    function cycleGroundpiece(direction:Int)
    {
        var count = groundpieceLibrary.definitions.length;

        if (count == 0)
        {
            return;
        }

        selectedPieceIndex += direction;

        if (selectedPieceIndex < 0)
        {
            selectedPieceIndex = count - 1;
        }

        if (selectedPieceIndex >= count)
        {
            selectedPieceIndex = 0;
        }

        updateUnifiedPalette();
    }

    function cycleObject(direction:Int)
    {
        var count = objectLibrary.definitions.length;

        if (count == 0)
        {
            return;
        }

        selectedObjectIndex += direction;

        if (selectedObjectIndex < 0)
        {
            selectedObjectIndex = count - 1;
        }

        if (selectedObjectIndex >= count)
        {
            selectedObjectIndex = 0;
        }

        updateUnifiedPalette();
    }

    function refreshSelection()
    {
        if (selectionOutline == null)
        {
            return;
        }

        var w:Int;
        var h:Int;

        if (selectedObjectPlacementIndex >= 0 && selectedObjectPlacementIndex < document.objects.length)
        {
            var placement = document.objects[selectedObjectPlacementIndex];
            var definition = objectLibrary.getById(placement.id);

            w = definition.bitmap.width;
            h = definition.bitmap.height;
        }
        else if (selectedPlacementIndex >= 0 && selectedPlacementIndex < document.pieces.length)
        {
            var placement = document.pieces[selectedPlacementIndex];
            var definition = groundpieceLibrary.getById(placement.id);

            w = definition.bitmap.width;
            h = definition.bitmap.height;
        }
        else
        {
            selectionOutline.visible = false;
            return;
        }

        selectionOutline.makeGraphic(w, h, FlxColor.TRANSPARENT, true);

        var pixels = selectionOutline.pixels;
        var thickness = 2;

        pixels.fillRect(new Rectangle(0, 0, w, thickness), FlxColor.CYAN);
        pixels.fillRect(new Rectangle(0, h - thickness, w, thickness), FlxColor.CYAN);
        pixels.fillRect(new Rectangle(0, 0, thickness, h), FlxColor.CYAN);
        pixels.fillRect(new Rectangle(w - thickness, 0, thickness, h), FlxColor.CYAN);

        selectionOutline.dirty = true;

        updateSelectionPosition();

        selectionOutline.visible = true;
    }

    function updateSelectionPosition()
    {
        if (selectedObjectPlacementIndex >= 0 && selectedObjectPlacementIndex < document.objects.length)
        {
            var placement = document.objects[selectedObjectPlacementIndex];

            selectionOutline.x = placement.x;
            selectionOutline.y = placement.y;
        }
        else if (selectedPlacementIndex >= 0 && selectedPlacementIndex < document.pieces.length)
        {
            var placement = document.pieces[selectedPlacementIndex];

            selectionOutline.x = placement.x;
            selectionOutline.y = placement.y;
        }
    }

    function cycleMusic(direction:Int)
    {
        var count = musicLibrary.tracks.length;

        if (count == 0)
        {
            return;
        }

        selectedMusicIndex += direction;

        if (selectedMusicIndex < 0)
        {
            selectedMusicIndex = count - 1;
        }

        if (selectedMusicIndex >= count)
        {
            selectedMusicIndex = 0;
        }

        document.music = musicLibrary.tracks[selectedMusicIndex].asset;

        previewMusic();

        commitEdit(false);
    }

    function previewMusic()
    {
        if (document.music == null || document.music == "")
        {
            if (FlxG.sound.music != null)
            {
                FlxG.sound.music.stop();
            }

            return;
        }

        FlxG.sound.playMusic(document.music, 1, true);
    }

    function rebuildTerrain()
    {
        var pieces:Array<GroundPiece> = [];

        for (placement in document.pieces)
        {
            var definition = groundpieceLibrary.getById(placement.id);

            pieces.push(new GroundPiece(definition.bitmap, placement.x, placement.y, definition.type, definition.collisionMask));
        }

        terrain.replacePieces(pieces);
    }

    function rebuildObjects():Void
    {
        for (sprite in objectSprites)
        {
            remove(sprite, true);
        }

        objectSprites = [];

        var insertIndex = members.indexOf(dragPreview);

        if (insertIndex < 0)
        {
            insertIndex = members.length;
        }

        for (placement in document.objects)
        {
            var definition = objectLibrary.getById(placement.id);

            var sprite = new FlxSprite(placement.x, placement.y);

            sprite.loadGraphic(definition.bitmap, false, 0, 0, true);

            objectSprites.push(sprite);

            insert(insertIndex, sprite);
            insertIndex += 1;
        }
    }

    function commitEdit(rebuild:Bool = true)
    {
        history.push(document.toJson());

        if (rebuild)
        {
            syncTerrainToDocument();
        }

        updatePlayerMarker();
        refreshSelection();
        updateHUD();
    }

    function undo()
    {
        var snapshot = history.undo();

        if (snapshot == null)
        {
            return;
        }

        restoreDocument(snapshot);
    }

    function redo()
    {
        var snapshot = history.redo();

        if (snapshot == null)
        {
            return;
        }

        restoreDocument(snapshot);
    }

    function restoreDocument(snapshot:String)
    {
        document = LevelDocument.fromJson(snapshot);

        selectedPlacementIndex = -1;

        selectedMusicIndex = musicLibrary.findOrAdd(document.music);

        syncTerrainToDocument();
        updatePlayerMarker();
        refreshSelection();
        updateUnifiedPalette();
        previewMusic();
        updateHUD();
    }

    function startPlaytest()
    {
        var snapshot = document.toJson();

        FlxG.switchState(() -> new PlayState(null, snapshot, levelAssetPath, savePath, history, currentFilePath));
    }

    function updateHUD()
    {
        hud.text = "Level Size: " + document.width + "x" + document.height;
    }

    function finishPieceDrag()
    {
        draggingPiece = false;

        dragPreview.visible = false;

        if (!dragChanged)
        {
            updateSelectionPosition();
            return;
        }

        if (selectedPlacementIndex < 0 || selectedPlacementIndex >= document.pieces.length)
        {
            return;
        }

        var placement = document.pieces[selectedPlacementIndex];

        terrain.movePiece(selectedPlacementIndex, dragTargetX, dragTargetY);

        placement.x = dragTargetX;
        placement.y = dragTargetY;

        history.push(document.toJson());

        refreshSelection();
        updateHUD();

        dragChanged = false;
    }

    override public function destroy()
    {
        if (terrain != null)
        {
            remove(terrain.sprite, true);
            terrain.destroy();
        }

        super.destroy();
    }

    function openLevelDialog()
    {
        #if sys
        fileDialog = new FileDialog();

        fileDialog.onSelect.add(function(path:String)
        {
            fileDialog = null;

            loadLevelFromPath(path);
        });

        fileDialog.onCancel.add(function()
        {
            fileDialog = null;
        });

        var opened = fileDialog.browse(FileDialogType.OPEN, "json", savePath, "Open Level");

        if (!opened)
        {
            fileDialog = null;
            trace("File browser is not supported on this platform!");
        }
        #else
        trace("Opening files from a path requires a desktop build! How did you even get here?");
        #end
    }

    function loadLevelFromPath(path:String)
    {
        #if sys
        try
        {
            var json = sys.io.File.getContent(path);
            var loadedDocument = LevelDocument.fromJson(json);

            if (loadedDocument.width < 1 || loadedDocument.height < 1)
            {
                throw "Invalid level dimensions!";
            }

            for (placement in loadedDocument.pieces)
            {
                groundpieceLibrary.getById(placement.id);
            }

            document = loadedDocument;

            currentFilePath = path;
            levelAssetPath = path;
            savePath = path;

            history.reset(document.toJson());

            selectedPlacementIndex = -1;

            draggingPiece = false;
            draggingPlayer = false;

            dragChanged = false;

            selectedMusicIndex = musicLibrary.findOrAdd(document.music);

            syncTerrainToDocument();
            updatePlayerMarker();
            refreshSelection();
            updateUnifiedPalette();

            FlxG.camera.scroll.set(0, 0);

            updateCameraBounds();
            previewMusic();
            updateHUD();

            trace("Loaded level: " + path);
        }
        catch (error:Dynamic)
        {
            trace("Failed to load level: " + path + ": " + error);
        }

        #else
        trace("File loading is unavailable on this platform! How did you even get here?");
        #end
    }

    function save()
    {
        if (currentFilePath != null && currentFilePath != "")
        {
            saveToPath(currentFilePath);
        }
        else
        {
            saveAsDialog();
        }
    }

    function saveAsDialog()
    {
        #if sys
        fileDialog = new FileDialog();

        fileDialog.onSelect.add(function(path:String)
        {
            fileDialog = null;

            var finalPath = path;

            if (!StringTools.endsWith(finalPath.toLowerCase(), ".json"))
            {
                finalPath += ".json";
            }

            saveToPath(finalPath);
        });

        fileDialog.onCancel.add(function()
        {
            fileDialog = null;
        });

        var opened = fileDialog.browse(FileDialogType.SAVE, "json", savePath, "Save Level As");

        if (!opened)
        {
            fileDialog = null;
            trace("File browser is not supported on this platform!");
        }
        #else
        trace("File saving requires a desktop build! How did you even get here?");
        #end
    }

    function saveToPath(path:String):Void
    {
        #if sys
        try
        {
            var json = document.toJson();

            sys.io.File.saveContent(path, json);

            currentFilePath = path;
            savePath = path;
            levelAssetPath = path;

            updateHUD();

            trace("Saved level: " + path);
        }
        catch (error:Dynamic)
        {
            trace("Failed to save level: " + path + ": " + error);
        }
        #else
        trace("File saving requires a desktop build! How did you even get here?");
        #end
    }

    function updateLevelGradient()
    {
        if (levelGradient != null && displayedGradientBottom == document.gradientBottom && displayedGradientTop == document.gradientTop)
        {
            return;
        }

        if (levelGradient != null)
        {
            remove(levelGradient, true);
        }

        var parsedTop = FlxColor.fromString(document.gradientTop);
        var parsedBottom = FlxColor.fromString(document.gradientBottom);

        var topColor:FlxColor = parsedTop == null ? 0x45C4FF : cast parsedTop;
        var bottomColor:FlxColor = parsedBottom == null ? FlxColor.WHITE : cast parsedBottom;

        levelGradient = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [topColor, bottomColor], 1, 90);

        levelGradient.scrollFactor.set(0, 0);

        displayedGradientTop = document.gradientTop;
        displayedGradientBottom = document.gradientBottom;

        insert(0, levelGradient);
    }

    function addFixedSprite(sprite:FlxSprite):FlxSprite
    {
        sprite.scrollFactor.set(0, 0);
        add(sprite);
        return sprite;
    }

    function addActionButton(label:String, x:Int, y:Int, width:Int, height:Int, action:String):FlxSprite
    {
        var background = new FlxSprite(x, y);
        background.makeGraphic(width, height, 0xFF343B50, true);
        background.scrollFactor.set(0, 0);
        add(background);

        var text = new FlxText(x + 3, y + Std.int((height - 14) / 2), width - 6, label, 8);

        text.alignment = "center";
        text.scrollFactor.set(0, 0);
        add(text);

        actionButtonRects.push(new Rectangle(x, y, width, height));
        actionButtonActions.push(action);

        return background;
    }

    function createEditorGUI()
    {
        sidebarX = FlxG.width - sidebarWidth;

        var sidebar = new FlxSprite(sidebarX, 0);
        sidebar.makeGraphic(sidebarWidth, FlxG.height, 0x75C4CEFF, true);
        addFixedSprite(sidebar);

        createToolButtons();

        addActionButton("W-", 154, 4, 34, 30, "widthMinus");
        addActionButton("W+", 191, 4, 34, 30, "widthPlus");
        addActionButton("H-", 228, 4, 34, 30, "heightMinus");
        addActionButton("H+", 265, 4, 34, 30, "heightPlus");

        groundTabBackground = addActionButton("Ground Pieces", sidebarX + 7, 7, 100, 30, "tabGround");
        objectTabBackground = addActionButton("Objects", sidebarX + 110, 7, 99, 30, "tabObjects");

        addActionButton("<", sidebarX + 8, FlxG.height - 174, 48, 24, "palettePrevious");
        addActionButton(">", sidebarX + 160, FlxG.height - 174, 48, 24, "paletteNext");

        addActionButton("<", sidebarX + 8, FlxG.height - 143, 30, 25, "musicPrevious");
        addActionButton(">", sidebarX + 178, FlxG.height - 143, 30, 25, "musicNext");

        musicLabel = new FlxText(sidebarX + 42, FlxG.height - 140, 132, "", 10);
        musicLabel.alignment = "center";
        addFixedSprite(musicLabel);

        var buttonY = FlxG.height - 46;
        var x = 5;

        addActionButton("Save", x, buttonY, 82, 40, "save");
        x += 87;
        addActionButton("Open", x, buttonY, 82, 40, "open");
        x += 87;
        addActionButton("Save As", x, buttonY, 104, 40, "saveAs");
        x += 109;
        addActionButton("Play", x, buttonY, 72, 40, "playtest");
        x += 77;
        addActionButton("Back", x, buttonY, 54, 40, "layerBack");
        x += 59;
        addActionButton("Front", x, buttonY, 54, 40, "layerFront");
        x += 59;
        addActionButton("Delete", x, buttonY, 60, 40, "delete");

        updatePaletteTabs();
        updateMusicLabel();
        updateToolButtons();
    }

    function createToolButtons()
    {
        for (i in 0...toolButtonModes.length)
        {
            var x = 4 + i * 36;
            var y = 4;

            var background = new FlxSprite(x, y);
            background.makeGraphic(32, 32, 0xFF505A70, true);

            addFixedSprite(background);
            toolButtonBackgrounds.push(background);

            var icon = new FlxSprite(x + 2, y + 2);

            var path = toolIconPaths[i];

            if (path != "" && Assets.exists(path))
            {
                icon.loadGraphic(path);
                icon.setGraphicSize(28, 28);
                icon.updateHitbox();

                addFixedSprite(icon);
            }
            else
            {
                trace("did something wrong lol");
            }

            toolButtonRects.push(new Rectangle(x, y, 32, 32));
        }
    }

    function updateToolButtons()
    {
        for (i in 0...toolButtonBackgrounds.length)
        {
            var selected = toolButtonModes[i] == tool;

            toolButtonBackgrounds[i].makeGraphic(32, 32, selected ? 0xFFB4C4D8 : 0xFF3B404B, true);
        }
    }

    function updatePaletteTabs()
    {
        groundTabBackground.makeGraphic(100, 30, paletteMode == "ground" ? 0xFF6A8DCE : 0xFF344D97, true);
        objectTabBackground.makeGraphic(99, 30, paletteMode == "objects" ? 0xFF6A8DCE : 0xFF344D97, true);
    }

    function setPaletteMode(mode:String)
    {
        paletteMode = mode;
        palettePage = 0;

        if (tool == "place" || tool == "object")
        {
            tool = mode == "ground" ? "place" : "object";
        }

        updatePaletteTabs();
        updateUnifiedPalette();
        updateToolButtons();
        updateHUD();
    }

    function updateUnifiedPalette()
    {
        for (sprite in paletteTileSprites)
        {
            remove(sprite, true);
        }

        paletteTileSprites = [];
        paletteTileRects = [];
        paletteTileIndices = [];

        var definitionCount = paletteMode == "ground" ? groundpieceLibrary.definitions.length : objectLibrary.definitions.length;

        var rows = Std.int(Math.max(1, Math.floor((FlxG.height - 240) / 66)));
        var pageSize = rows * 3;

        var start = palettePage * pageSize;

        if (start >= definitionCount && palettePage > 0)
        {
            palettePage -= 1;
            start = palettePage * pageSize;
        }

        var end = Std.int(Math.min(definitionCount, start + pageSize));

        for (i in start...end)
        {
            var bitmap:BitmapData;
            var itemName:String;

            if (paletteMode == "ground")
            {
                var definition = groundpieceLibrary.definitions[i];

                bitmap = definition.bitmap;
                itemName = definition.name;
            }
            else
            {
                var definition = objectLibrary.definitions[i];

                bitmap = definition.bitmap;
                itemName = definition.name;
            }

            var localIndex = i;
            var slot = i - start;

            var column = slot % 3;
            var row = Std.int(slot / 3);

            var x = sidebarX + 8 + column * 64;
            var y = 49 + row * 64;

            var isSelected = paletteMode == "ground" ? localIndex == selectedPieceIndex : localIndex == selectedObjectIndex;

            var background = new FlxSprite(x, y);
            background.makeGraphic(paletteTileSize, paletteTileSize, isSelected ? 0xFF9DB7E9 : 0xFFF5F6FC, true);

            addFixedSprite(background);
            paletteTileSprites.push(background);

            var preview = new FlxSprite();

            preview.loadGraphic(bitmap, false, 0, 0, true);

            var scale = Math.min(1, Math.min(44 / bitmap.width, 38 / bitmap.height));

            var previewWidth = Std.int(bitmap.width * scale);
            var previewHeight = Std.int(bitmap.height * scale);

            preview.setGraphicSize(previewWidth, previewHeight);
            preview.updateHitbox();

            preview.x = x + (paletteTileSize - preview.width) / 2;
            preview.y = y + 2;

            addFixedSprite(preview);
            paletteTileSprites.push(preview);

            if (itemName.length > 8)
            {
                itemName = itemName.substr(0, 7) + ".";
            }

            var label = new FlxText(x + 1, y + 42, paletteTileSize - 2, itemName, 8);

            label.alignment = "center";

            addFixedSprite(label);
            paletteTileSprites.push(label);

            paletteTileRects.push(new Rectangle(x, y, paletteTileSize, paletteTileSize));

            paletteTileIndices.push(localIndex);
        }

        if (definitionCount == 0)
        {
            var emptyText = new FlxText(sidebarX + 12, 70, sidebarWidth - 24, paletteMode == "ground" ? "No groundpieces loaded" : "No objects loaded.", 12);

            addFixedSprite(emptyText);
            paletteTileSprites.push(emptyText);
        }
    }

    function handleGUIAction(action:String):Void
    {
        switch (action)
        {
            case "tabGround":
                setPaletteMode("ground");

            case "tabObjects":
                setPaletteMode("objects");

            case "palettePrevious":
                if (palettePage > 0)
                {
                    palettePage -= 1;
                    updateUnifiedPalette();
                }

            case "paletteNext":
                var rows = Std.int(Math.max(1, Math.floor((FlxG.height - 240) / 66)));
                var pageSize = rows * 3;

                var count = paletteMode == "ground" ? groundpieceLibrary.definitions.length : objectLibrary.definitions.length;

                if ((palettePage + 1) * pageSize < count)
                {
                    palettePage++;
                    updateUnifiedPalette();
                }

            case "save":
                save();

            case "open":
                openLevelDialog();

            case "saveAs":
                saveAsDialog();

            case "playtest":
                startPlaytest();

            case "delete":
                deleteSelected();

            case "layerBack":
                moveSelectedGroundpieceLayer(-1);

            case "layerFront":
                moveSelectedGroundpieceLayer(1);

            case "widthMinus":
                resizeLevel(-resizeStep, 0);

            case "widthPlus":
                resizeLevel(resizeStep, 0);

            case "heightMinus":
                resizeLevel(0, -resizeStep);

            case "heightPlus":
                resizeLevel(0, resizeStep);

            case "musicPrevious":
                cycleMusic(-1);
                updateMusicLabel();

            case "musicNext":
                cycleMusic(1);
                updateMusicLabel();
        }
    }

    function updateMusicLabel():Void
    {
        if (musicLibrary.tracks.length == 0)
        {
            musicLabel.text = "No Music";
            return;
        }

        musicLabel.text = musicLibrary.tracks[selectedMusicIndex].name;
    }

    function handleGUIInput():Bool
    {
        var x = FlxG.mouse.viewX;
        var y = FlxG.mouse.viewY;

        if (FlxG.mouse.justPressed)
        {
            for (i in 0...toolButtonRects.length)
            {
                if (toolButtonRects[i].contains(x, y))
                {
                    var mode = toolButtonModes[i];

                    if (mode == "place")
                    {
                        setPaletteMode("ground");
                    }
                    else if (mode == "object")
                    {
                        setPaletteMode("objects");
                    }

                    setTool(mode);
                    return true;
                }
            }

            for (i in 0...actionButtonRects.length)
            {
                if (actionButtonRects[i].contains(x, y))
                {
                    handleGUIAction(actionButtonActions[i]);
                    return true;
                }
            }

            for (i in 0...paletteTileRects.length)
            {
                if (paletteTileRects[i].contains(x, y))
                {
                    var index = paletteTileIndices[i];

                    if (paletteMode == "ground")
                    {
                        selectedPieceIndex = index;
                        setTool("place");
                    }
                    else
                    {
                        selectedObjectIndex = index;
                        setTool("object");
                    }

                    updateUnifiedPalette();
                    updateHUD();

                    return true;
                }
            }
        }

        return mouseOverEditorGUI();
    }

    function mouseOverEditorGUI():Bool
    {
        var x = FlxG.mouse.viewX;
        var y = FlxG.mouse.viewY;

        return x >= sidebarX || (x < 310 && y <= 40) || (y >= FlxG.height - 50 && x < sidebarX);
    }
}