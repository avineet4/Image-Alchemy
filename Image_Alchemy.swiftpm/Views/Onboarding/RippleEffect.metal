//
//  File.metal
//  Image Alchemy
//
//  Created by Avineet Singh on 27/02/2026.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
using namespace metal;

[[ stitchable ]]
half4 RippleEffect(
    float2 position,
    SwiftUI::Layer layer,
    float2 origin,
    float time,
    float amplitude,
    float frequency,
    float decay,
    float speed
) {
    // Distance from ripple origin
    float distance = length(position - origin);

    // Delay so ripple propagates outward over time
    float delay = distance / max(speed, 0.0001);
    time -= delay;
    time = max(0.0, time);

    // Oscillating ripple that decays over time
    float rippleAmount = amplitude * sin(frequency * time) * exp(-decay * time);

    // Direction from origin to current pixel
    float2 dir = position - origin;
    float len = length(dir);
    float2 n = len > 0.0001 ? dir / len : float2(0.0, 0.0);

    // Distorted sampling position
    float2 newPosition = position + rippleAmount * n;

    // Sample original layer at distorted position
    half4 color = layer.sample(newPosition);

    // Subtle brightness modulation based on ripple strength
    float norm = (abs(amplitude) > 0.0001) ? (rippleAmount / amplitude) : 0.0;
    color.rgb += half3(0.3 * norm * color.a);

    return color;
}
