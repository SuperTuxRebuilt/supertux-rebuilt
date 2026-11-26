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

class EditorHistory
{
    var snapshots:Array<String> = [];
    var currentIndex:Int = -1;

    public var maxHistory:Int = 100;

    public function new()
    {
    }

    public function reset(json:String)
    {
        snapshots = [json];
        currentIndex = 0;
    }

    public function push(json:String)
    {
        if (currentIndex >= 0 && snapshots[currentIndex] == json)
        {
            return;
        }

        snapshots.splice(currentIndex + 1, snapshots.length - currentIndex - 1);

        snapshots.push(json);
        currentIndex += 1;

        if (snapshots.length > maxHistory)
        {
            snapshots.shift();
            currentIndex -= 1;
        }
    }

    public function undo():Null<String>
    {
        if (currentIndex <= 0)
        {
            return null;
        }

        currentIndex -= 1;

        return snapshots[currentIndex];
    }

    public function redo():Null<String>
    {
        if (currentIndex >= snapshots.length - 1)
        {
            return null;
        }

        currentIndex += 1;

        return snapshots[currentIndex];
    }

    public function canUndo():Bool
    {
        return currentIndex > 0;
    }

    public function canRedo():Bool
    {
        return currentIndex < snapshots.length - 1;
    }
}