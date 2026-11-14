# OneLife — Cat Study Glossy V2 art acceptance

**Status:** illustrated source imported; mechanical QA must pass on GitHub; visual/device approval pending.

## Source
- Original 12-pose lavender Cat with white tuft, pink ears, glossy lighting and books. `assets/characters-v2/cat/study/sheet_illustrated.webp` SHA256 `b922acdf5f3c8d5c8d905e02b0f765b1413ec007a1d6859867e51c91456d4438`.
- 4×3 grid of 256px RGBA cells, 140 ms/frame, `loop=false`; animation stops with book in paws rather than popping back to frame 1.

## Pose sequence
1. Spots a closed book.
2. Reaches for the book.
3. Lifts the book.
4. Opens it excitedly.
5. Reads attentively.
6. Tracks page content.
7. Turns a page.
8. Writes notes.
9. Pauses to reflect.
10. Gets an idea.
11. Celebrates the lesson.
12. Closes the book contentedly.

## Gates
- [x] Source geometry/alpha and distinct adjacent pose QA locally.
- [x] GitHub source/render SHA verification and automated check pass (run 43578370280).
- [ ] Art reviewer confirms expression and page-motion progression (no teleporting props) and stable silhouette.
- [ ] Confirm alpha edges contain no former white/checkerboard matte, especially around eyes and book at 64px.
- [ ] Check 64px/96px/144px on light/dark UI; honor reduced motion and voiceover labels.
- [ ] Low-end Android memory/power/render test; iOS in-app display test.

**Source passes structural tests, but this alone does not prove seamless movement or product art acceptance.**
