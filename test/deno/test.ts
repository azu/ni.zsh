import { assertEquals } from "https://deno.land/std@0.214.0/assert/mod.ts";
import chalk from "chalk";

Deno.test("imports work", () => {
  assertEquals(typeof chalk.blue, "function");
});
