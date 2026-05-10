import { pathToFileURL } from "node:url";

export function message() {
  return "hello";
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  console.log(message());
}
