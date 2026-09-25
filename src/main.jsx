import React from "react";
import ReactDOM from "react-dom/client";
import DinoBuilder from "./App.jsx";
import { initCloudSync } from "./cloud/sync.js";

initCloudSync();

ReactDOM.createRoot(document.getElementById("root")).render(<DinoBuilder />);
