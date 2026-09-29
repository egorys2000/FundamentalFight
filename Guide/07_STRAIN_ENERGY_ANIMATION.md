# Strain-energy animation

The string's visual motion should feel like a loaded line releasing tension,
not like a UI tween sliding points from A to B.

## Model

For each pull, game logic computes:

- `q`: the current geometric representative;
- `q*`: the legal canonical/tight representative;
- `x = q* - q`: geometric displacement;
- `E = 1/2 k ||x||²`: visual strain energy.

The prototype uses a normalized spring coordinate for the animation, while
energy is measured over all corresponding loop points:

```text
x'' = k(1 - progress) - c progress'
```

Godot uses stiffness `k = 42` and damping `c = 10.5`. This produces a quick
pull with restrained release/overshoot instead of a linear or quadratic tween.

## What energy controls

Energy controls spring motion, a small visual thickening while the line is
loaded, and debug telemetry. It does not control collision legality, topology,
damage, rope health, or whether a pull succeeds.

If an interpolated frame would cross an obstacle, spring velocity is dissipated
and the frame is clamped. The authoritative target was validated before
animation starts. The animation snaps to that exact target only after
displacement, velocity, and residual energy are all small.

## Tuning

- Increase stiffness for a faster pull, not for simulated rope weight.
- Increase damping when overshoot looks unstable.
- Keep thickness changes subtle so the string never suggests rope HP.
- Never let animation decide a topological result after the pull starts.
