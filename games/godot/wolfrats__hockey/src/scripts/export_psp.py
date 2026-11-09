#!/usr/bin/env python3
import sys
import json
import base64
import io
import os
import struct
from PIL import Image, ImageDraw

TOOL_BRUSH = 0
TOOL_1 = 1
TOOL_ERASER = 2
TOOL_FLOODFILL = 3
TOOL_ERASER_RECT = 6
TOOL_MOVE_RECT = 10
TOOL_COLOR_REPLACE = 18
TOOL_SELECTION_PASTE = 20

def apply_actions(img, actions, history_data=None):
    """
    Applies an array of PixelStudio actions to the given PIL Image.
    """
    if history_data is None:
        history_data = {}

    snapshot = history_data.get('_snapshot', '')
    if snapshot:
        if ',' in snapshot:
            base64_data = snapshot.split(',', 1)[1]
        else:
            base64_data = snapshot
        
        try:
            snapshot_bytes = base64.b64decode(base64_data)
            paste_img = Image.open(io.BytesIO(snapshot_bytes)).convert("RGBA")
            #img.alpha_composite(paste_img)
            img = paste_img
        except Exception as e:
            print(f"Error applying Tool 1 snapshot: {e}")

    for action in actions:
        #print(action)
        tool = action.get('Tool')
        #if tool in (TOOL_FLOODFILL, TOOL_COLOR_REPLACE, TOOL_MOVE_RECT):
            #print(action)
        
        if tool == TOOL_ERASER_RECT:
            # Tool 6: Eraser rectangle or Polygon
            meta_str = action.get('Meta', '{}')
            meta = {}
            try:
                if meta_str:
                    meta = json.loads(meta_str)
            except json.JSONDecodeError:
                pass
                
            if 'From' in meta and 'To' in meta:
                from_pt = meta.get('From', {})
                to_pt = meta.get('To', {})
                
                x1 = from_pt.get('X', 0)
                y1 = img.height - from_pt.get('Y', 0) - 1
                x2 = to_pt.get('X', 0)
                y2 = img.height - to_pt.get('Y', 0) - 1
                
                min_x, max_x = min(x1, x2), max(x1, x2)
                min_y, max_y = min(y1, y2), max(y1, y2)
                
                for y in range(min_y, max_y + 1):
                    for x in range(min_x, max_x + 1):
                        if 0 <= x < img.width and 0 <= y < img.height:
                            img.putpixel((x, y), (0, 0, 0, 0))
            else:
                pos_str = action.get('Positions', '')
                if pos_str:
                    pos_bytes = base64.b64decode(pos_str)
                    positions = []
                    for i in range(0, len(pos_bytes), 4):
                        if i+4 <= len(pos_bytes):
                            x, y = struct.unpack('<HH', pos_bytes[i:i+4])
                            y = img.height - y - 1
                            positions.append((x, y))
                    if len(positions) >= 3:
                        draw = ImageDraw.Draw(img)
                        draw.polygon(positions, fill=(0, 0, 0, 0))

        elif tool == TOOL_MOVE_RECT:
            # Tool 10: Rectangle Move Operation
            pos_str = action.get('Positions', '')
            meta_str = action.get('Meta', '{}')
            meta = {}
            try:
                if meta_str:
                    meta = json.loads(meta_str)
            except json.JSONDecodeError:
                pass
            if 'From' in meta and 'To' in meta:
                from_pt = meta.get('From', {})
                to_pt = meta.get('To', {})

                # Get source rectangle bounds (invert Y for PIL and adjust for 0-indexing)
                src_x1 = from_pt.get('X', 0)
                src_y1 = img.height - from_pt.get('Y', 0) - 1
                src_x2 = to_pt.get('X', 0)
                src_y2 = img.height - to_pt.get('Y', 0) - 1

                src_min_x, src_max_x = min(src_x1, src_x2), max(src_x1, src_x2)
                src_min_y, src_max_y = min(src_y1, src_y2), max(src_y1, src_y2)

                # Calculate movement delta from Positions (Start Point -> End Point)
                dx, dy = 0, 0
                if pos_str:
                    pos_bytes = base64.b64decode(pos_str)
                    if len(pos_bytes) >= 8:
                        px1, py1 = struct.unpack('<HH', pos_bytes[0:4])
                        px2, py2 = struct.unpack('<HH', pos_bytes[4:8])
                        dx = px2 - px1
                        dy = py1 - py2  # Invert Y delta: PixelStudio Y goes up, PIL Y goes down

                dst_min_x = src_min_x + dx
                dst_min_y = src_min_y + dy

                # Crop source area (+1 for inclusive right/bottom bounds)
                src_box = (src_min_x, src_min_y, src_max_x + 1, src_max_y + 1)
                cropped = img.crop(src_box)

                # Erase source area
                draw = ImageDraw.Draw(img)
                draw.rectangle([src_min_x, src_min_y, src_max_x, src_max_y], fill=(0, 0, 0, 0))

                # Paste to destination (using the cropped image itself as a mask for alpha compositing)
                img.paste(cropped, (dst_min_x, dst_min_y), cropped)
            elif pos_str:
                pos_bytes = base64.b64decode(pos_str)
                positions = []
                for i in range(0, len(pos_bytes), 4):
                    if i+4 <= len(pos_bytes):
                        x, y = struct.unpack('<HH', pos_bytes[i:i+4])
                        y = img.height - y
                        positions.append((x, y))
                
                if len(positions) >= 4:
                    # First two are source rect, next two are dest rect
                    src_x1, src_y1 = positions[0]
                    src_x2, src_y2 = positions[1]
                    dst_x1, dst_y1 = positions[2]
                    dst_x2, dst_y2 = positions[3]
                    
                    src_min_x, src_max_x = min(src_x1, src_x2), max(src_x1, src_x2)
                    src_min_y, src_max_y = min(src_y1, src_y2), max(src_y1, src_y2)
                    
                    dst_min_x, dst_max_x = min(dst_x1, dst_x2), max(dst_x1, dst_x2)
                    dst_min_y, dst_max_y = min(dst_y1, dst_y2), max(dst_y1, dst_y2)
                    
                    # Crop source area
                    # Box is (left, upper, right, lower)
                    src_box = (src_min_x, src_min_y, src_max_x + 1, src_max_y + 1)
                    cropped = img.crop(src_box)
                    
                    # Erase source area
                    draw = ImageDraw.Draw(img)
                    draw.rectangle([src_min_x, src_min_y, src_max_x, src_max_y], fill=(0, 0, 0, 0))
                    
                    # Resize if destination is different size
                    dst_w = dst_max_x - dst_min_x + 1
                    dst_h = dst_max_y - dst_min_y + 1
                    
                    if cropped.width != dst_w or cropped.height != dst_h:
                        cropped = cropped.resize((dst_w, dst_h))
                    
                    # Paste to destination
                    img.paste(cropped, (dst_min_x, dst_min_y), cropped)

        elif tool == TOOL_1:
            snapshot = history_data.get('_snapshot', '')
            if snapshot:
                if ',' in snapshot:
                    base64_data = snapshot.split(',', 1)[1]
                else:
                    base64_data = snapshot
                
                try:
                    snapshot_bytes = base64.b64decode(base64_data)
                    paste_img = Image.open(io.BytesIO(snapshot_bytes)).convert("RGBA")
                    #img.alpha_composite(paste_img)
                    #img = paste_img
                except Exception as e:
                    print(f"Error applying Tool 1 snapshot: {e}")

        # Tools that may use specific pixel positions and colors
        elif tool in (TOOL_BRUSH, TOOL_ERASER, TOOL_FLOODFILL, TOOL_COLOR_REPLACE):
            pos_str = action.get('Positions', '')
            col_str = action.get('Colors', '')
            
            if not pos_str:
                continue
                
            pos_bytes = base64.b64decode(pos_str)
            positions = []
            for i in range(0, len(pos_bytes), 4):
                if i+4 <= len(pos_bytes):
                    x, y = struct.unpack('<HH', pos_bytes[i:i+4])
                    y = img.height - y
                    positions.append((x, y))
            
            colors = []
            if col_str:
                col_bytes = base64.b64decode(col_str)
                for i in range(0, len(col_bytes), 4):
                    if i+4 <= len(col_bytes):
                        r, g, b, a = struct.unpack('<BBBB', col_bytes[i:i+4])
                        colors.append((r,g,b,a))
            
            if tool == TOOL_FLOODFILL or tool == TOOL_COLOR_REPLACE:
                for i, (x, y) in enumerate(positions):
                    color = colors[i] if i < len(colors) else colors[-1]
                    if 0 <= x < img.width and 0 <= y - 1 < img.height:
                        ImageDraw.floodfill(img, (x, y - 1), color)
            elif colors or tool == TOOL_ERASER:
                # Use putpixel to apply colors to specified positions
                for i, (x, y) in enumerate(positions):
                    if tool == TOOL_ERASER:
                        color = (0, 0, 0, 0)
                    else:
                        color = colors[i] if i < len(colors) else colors[-1]
                        
                    if 0 <= x < img.width and 0 <= y < img.height:
                        img.putpixel((x, y - 1), color)
                        
        elif tool == TOOL_SELECTION_PASTE:
            # Selection/Paste
            meta_str = action.get('Meta', '{}')
            try:
                meta = json.loads(meta_str)
            except json.JSONDecodeError:
                continue
                
            #print(action)

            rect = meta.get('RectSource', {})
            from_pt = rect.get('From', {})
            to_pt = rect.get('To', {})
            
            x1 = from_pt.get('X', 0)
            y1 = img.height - from_pt.get('Y', 0)
            x2 = to_pt.get('X', 0)
            y2 = img.height - to_pt.get('Y', 0)
            
            min_x, max_x = min(x1, x2), max(x1, x2)
            min_y, max_y = min(y1, y2), max(y1, y2)
            
            for y in range(min_y, max_y + 1):
                for x in range(min_x, max_x + 1):
                    if 0 <= x < img.width and 0 <= y < img.height:
                        img.putpixel((x, y - 1), (0, 0, 0, 0))

            pixels_str = meta.get('Pixels', '')
            rect = meta.get('Rect', {})
            rect_to = rect.get('To', {})
            rect_from = rect.get('From', {})
            x = rect_from.get('X', 0)
            y = rect_from.get('Y', 0)
            x2 = rect_to.get('X', 0)
            y2 = rect_to.get('Y', 0)
            
            if pixels_str:
                try:
                    pixels_bytes = base64.b64decode(pixels_str)
                    paste_img = Image.open(io.BytesIO(pixels_bytes)).convert("RGBA")
                    # Use alpha_composite to properly blend the pasted image
                    #img.alpha_composite(paste_img, (x, img.height - y - paste_img.height))
                    ep = 1 if img.height > 10 else 0
                    ep = 0
                    img.paste(paste_img, (x, img.height - y - paste_img.height + ep), paste_img)
                except Exception as e:
                    print(f"Error applying Tool 20: {e}")

    return img


def export_psp(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)

    for clip in data.get('Clips', []):
        clip_name = clip.get('Name', 'Unnamed_Clip')
        frames_images = []
        
        for frame in clip.get('Frames', []):
            layers = frame.get('Layers', [])
            if not layers:
                continue
            
            first_layer = layers[0]
            history_json_str = first_layer.get('_historyJson', '{}')
            try:
                history_data = json.loads(history_json_str)
            except json.JSONDecodeError:
                continue
            
            source = history_data.get('_source', '')
            if not source:
                continue
            
            if ',' in source:
                base64_data = source.split(',', 1)[1]
            else:
                base64_data = source
            
            image_bytes = base64.b64decode(base64_data)
            img = Image.open(io.BytesIO(image_bytes)).convert("RGBA")
            
            # Apply any actions from history
            actions = history_data.get('Actions', [])
            if actions:
                img = apply_actions(img, actions, history_data)
                
            frames_images.append(img)
        
        if not frames_images:
            print(f"No frames found for clip '{clip_name}'")
            continue
            
        total_width = sum(img.width for img in frames_images)
        max_height = max(img.height for img in frames_images)
        
        spritesheet = Image.new('RGBA', (total_width, max_height), (0, 0, 0, 0))
        
        current_x = 0
        for img in frames_images:
            spritesheet.paste(img, (current_x, 0))
            current_x += img.width
            
        # Clean clip name to avoid invalid characters
        safe_clip_name = "".join([c for c in clip_name if c.isalpha() or c.isdigit() or c==' ' or c=='-' or c=='_']).rstrip()
        out_filename = f"{safe_clip_name}.png"
        spritesheet.save(out_filename)
        print(f"Saved {out_filename}")

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python export_psp.py <file.psp>")
        sys.exit(1)
        
    export_psp(sys.argv[1])

