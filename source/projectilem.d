module projectilem;

import std.math;
import std.stdio;
import std.format;

import vars;

import raylib;

class Projectile
{
    Vector3 velocity;
    Vector3 target;
    Vector3 position;
    Color color;
    float height;
    int player;

    this(Color color,
         Vector3 position,
         Vector3 target,
         float height)
    {
        this.target = target;
        this.position = position;
        this.height = height;
        this.color = color;

        velocity = initialVelocity();
    }

    void update(float delta)
    {
        velocity.y += gravity * delta;
        position = Vector3Add(position, Vector3Scale(velocity, delta));
    }

    void draw()
    {
        DrawSphere(position, 0.2, color);
    }

    Vector3 initialVelocity()
    {
        float displacementY = target.y - position.y;
        Vector3 displacement = 
        {
            x: target.x - position.x,
            z: target.z - position.z
        };

        // Time = time to reach h + time to fall down
        float timeUp = sqrt(-2*height/gravity);
        float timeDown = sqrt(2*(displacementY-height)/gravity);

        // v = d / t or v = d * 1/t
        Vector3 initialVelocity = Vector3Scale(
            displacement, 
            1.0f / (timeUp + timeDown)
        );
        
        initialVelocity.y = sqrt(-2 * gravity * height);
        return initialVelocity;
    }
}

void updateProjectiles(float delta)
{
    foreach (Projectile p; projectiles)
    {
        if (p.target.y < p.position.y)
        {
            p.update(delta);
        }
        else
        {
            Explosion e = new Explosion(p.position, 0.3f, 1.0f, 2.0f);
            e.color = p.player == 1 ? colorOneTransparent : colorTwoTransparent,
            explosions.insertFront(e);
            projectiles.linearRemoveElement(p);
        }
    }
}

void drawProjectiles()
{
    foreach (Projectile p; projectiles)
    {
        p.draw();
    }
}

class Explosion
{
    Vector3 position;
    float duration;
    float curentTime = 0.0f;
    float radius = 0.0f;
    float startRadius;
    float endRadius;
    Color color;

    this(Vector3 position, float startRadius, float endRadius, float duration)
    {
        this.position = position;
        this.duration = duration;
        this.startRadius = startRadius;
        this.endRadius = endRadius;
    }

    void update(float delta)
    {
        curentTime += delta;
        radius = curentTime/duration * endRadius + startRadius;
    }

    void draw()
    {
        DrawSphere(position, radius, color);
    }
}

void updateExplosions(float delta)
{
    foreach (Explosion e; explosions)
    {
        if (e.curentTime < e.duration)
        {
            e.update(delta);   
        }
        else
        {
            explosions.linearRemoveElement(e);
        }
    }
}

void drawExplosions()
{
    foreach (Explosion e; explosions)
    {
        e.draw();   
    }
}
