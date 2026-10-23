export class PhaserDebugDraw
{
    constructor (graphics, width, height, scale)
    {
        this.scale = scale;
        this.width = width;
        this.height = height;

        this.drawingBounds = new b2AABB();
        this.positionOffset = new b2Vec2();
        this.p0 = new b2Vec2();

        this.useDrawingBounds = false;

        this.drawShapes = true;
        this.drawJoints = false;
        this.drawAABBs = false;
        this.drawMass = false;
        this.drawContacts = false;
        this.drawGraphColors = false;
        this.drawContactNormals = false;
        this.drawContactImpulses = false;
        this.drawFrictionImpulses = false;

        this.context = graphics;

        this.SetPosition(width, 0);
    }

    b2TransformPointOut (t, p, out)
    {
        out.x = (t.q.c * p.x - t.q.s * p.y) + t.p.x;
        out.y = (t.q.s * p.x + t.q.c * p.y) + t.p.y;
    }

    DrawPolygon (xf, vs, ps, col, graphics)
    {
        const p0 = this.p0;
        const scale = this.scale;
    
        const cX = (this.width >> 1) + this.positionOffset.x;
        const cY = (this.height >> 1) + this.positionOffset.y;
    
        const points = [];

        for (let i = 0; i < ps; i++)
        {
            this.b2TransformPointOut(xf, vs[i], p0);

            p0.y = -p0.y;
            
            const x = scale * p0.x + cX;
            const y = scale * p0.y + cY;

            points.push({ x, y });
        }
    
        graphics.lineStyle(1, col, 1);
        graphics.strokePoints(points, false, true);
    }

    DrawSolidPolygon (xf, vs, ps, rad, col, graphics)
    {
        const p0 = this.p0;
        const scale = this.scale;
    
        const cX = (this.width >> 1) + this.positionOffset.x;
        const cY = (this.height >> 1) + this.positionOffset.y;
    
        const points = [];

        for (let i = 0; i < ps; i++)
        {
            this.b2TransformPointOut(xf, vs[i], p0);

            p0.y = -p0.y;
            
            const x = scale * p0.x + cX;
            const y = scale * p0.y + cY;

            points.push({ x, y });
        }
    
        graphics.lineStyle(1, col, 1); // Use the radius for line width
        graphics.fillStyle(col, 0.5);

        graphics.fillPoints(points, false, true);
        graphics.strokePoints(points, false, true);
    }

    DrawCircle (center, rad, col, graphics)
    {
        const scale = this.scale;

        const cX = (this.width >> 1) + this.positionOffset.x;
        const cY = (this.height >> 1) + this.positionOffset.y;

        const transformedCenterX = scale * cX + cX;
        const transformedCenterY = -(scale * cY + cY);
        
        graphics.lineStyle(1, col, 1);
        graphics.strokeCircle(transformedCenterX, transformedCenterY, rad * scale, 0, 2 * Math.PI);
    }

    DrawSolidCircle (xf, rad, col, graphics)
    {
        const scale = this.scale;

        const cX = (this.width >> 1) + this.positionOffset.x;
        const cY = (this.height >> 1) + this.positionOffset.y;
    
        const transformedCenterX = scale * xf.p.x + cX;
        const transformedCenterY = -(scale * xf.p.y) + cY;
    
        const scaledRadius = rad * scale;
    
        graphics.fillStyle(col, 0.5);
        graphics.fillCircle(transformedCenterX, transformedCenterY, scaledRadius, 0, 2 * Math.PI);
    
        graphics.lineStyle(1, col, 1);
        graphics.strokeCircle(transformedCenterX, transformedCenterY, scaledRadius, 0, 2 * Math.PI);
    }
    
    DrawSolidCapsule (p1, p2, radius, col, graphics)
    {
        const scale = this.scale;
    
        const cX = (this.width >> 1) + this.positionOffset.x;
        const cY = (this.height >> 1) + this.positionOffset.y;
    
        const transformedP1X = (scale * p1.x) + cX;
        const transformedP1Y = (scale * -p1.y) + cY;
        const transformedP2X = (scale * p2.x) + cX;
        const transformedP2Y = (scale * -p2.y) + cY;
    
        const dx = transformedP2X - transformedP1X;
        const dy = transformedP2Y - transformedP1Y;
        const length = Math.sqrt(dx * dx + dy * dy);
        const angle = Math.atan2(dy, dx);
    
        graphics.save();
        graphics.translateCanvas(transformedP1X, transformedP1Y);
        graphics.rotateCanvas(angle);
    
        graphics.fillStyle(col, 0.5);
        graphics.lineStyle(1, col, 1);
    
        graphics.beginPath();
        
        graphics.arc(0, 0, radius * scale, Math.PI / 2, -Math.PI / 2);
        graphics.lineTo(length, -radius * scale);
        graphics.arc(length, 0, radius * scale, -Math.PI / 2, Math.PI / 2);
        graphics.lineTo(0, radius * scale);

        graphics.closePath();

        graphics.fill();
        graphics.stroke();

        graphics.restore();
    }
    
    DrawSegment (p1, p2, col, graphics)
    {
        const scale = this.scale;

        const cX = (this.width >> 1) + this.positionOffset.x;
        const cY = (this.height >> 1) + this.positionOffset.y;

        const v1X = (scale * p1.x) + cX;
        const v1Y = (scale * -p1.y) + cY;
        const v2X = (scale * p2.x) + cX;
        const v2Y = (scale * -p2.y) + cY;

        graphics.lineStyle(1, col, 1);
        graphics.lineBetween(v1X, v1Y, v2X, v2Y);
    }

    DrawPoint (x, y, radius, col, graphics)
    {
        this.DrawSolidCircle({ p: { x, y } }, radius, col, graphics);
    }

    SetPosition (x, y)
    {
        // use half width and height to make the virtual 'camera' look at (x, y)
        this.positionOffset.x = this.width / 2 - x;
        this.positionOffset.y = y - this.height / 2;
    }

    DrawImagePolygon (xf, shape, ctx)
    {
        //  NOOP
    }

    DrawImageCircle (xf, rad, shape, ctx)
    {
        //  NOOP
    }

    DrawImageCapsule (p1, p2, radius, shape, ctx)
    {
        //  NOOP
    }
}
