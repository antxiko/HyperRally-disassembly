# The game

Hyper Rally is a rally race seen from behind the car, down a road drawn in fake
3D. You drive one car through **twelve stages**, each with its own scenery: day,
tunnel, snow, desert, a storm that throws lightning, and **two run at night**
under a field of scrolling stars.

## The dashboard

Under the road sits a dashboard the code keeps up to date every frame:

- a **speedometer** in km/h (drawn by 0x69E7 from the speed at 0xE085),
- a **fuel gauge** whose needle drops as you go (0x6A49) and blinks a warning
  when it runs low (0x6AA9),
- a **gear** indicator that shifts with the speed (0x6ACF), and
- a **clock** that counts up in BCD (0x6B0E).

## Driving

The wheel comes from 0x6643, the accelerator and brake from 0x6940. The car is
six sprites (template at 0x66E2) that 0x65FA slides sideways as you steer. Rival
cars come up the road; hitting one, or a roadside obstacle, brakes you hard.

## The rally

The stage number lives in 0xE060 and runs from 1 to twelve. Reaching the end of
a stage's track advances it; at stage thirteen the rally is over. Each stage
also loads its own parameter into 0xE061, and that is what decides whether the
car skids, whether the sky carries stars, and whether lightning falls.
