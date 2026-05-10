import test from "node:test";
import assert from "node:assert/strict";

import { message } from "../src/main.js";

test("message", () => {
  assert.equal(message(), "hello");
});
