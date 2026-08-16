# MASAR - Asset Manager for 3ds Max

**Native MAXScript asset management for Autodesk 3ds Max.**

MASAR is a lightweight asset management tool designed to help 3D artists organize, inspect, save, relink, and package project assets directly inside 3ds Max.

Built with **native MAXScript** to minimize external dependencies and provide broad compatibility across 3ds Max versions.

---

## ✨ Features

- 🔍 **Asset Scanning**
  - Scan the current 3ds Max scene for referenced assets.
  - View asset type, status, and file path.

- 💾 **Asset Saving**
  - Save selected assets.
  - Save all available assets.
  - Keep project assets organized in a dedicated MASAR folder.

- 🔗 **Asset Relinking**
  - Relink supported assets to a new location.
  - Quickly manage missing or moved project files.

- 📦 **Project Packaging**
  - Package project assets using 3ds Max's native archive functionality.
  - Collect project files into a portable package.

- 📁 **Source & MASAR Locations**
  - Open the original asset location.
  - Open the MASAR asset folder.
  - Copy asset paths quickly.

- 🔎 **Asset Search & Filtering**
  - Search assets by name or path.
  - Filter assets by type.

- 🌐 **Language Support**
  - English
  - العربية

- 🖥️ **Native 3ds Max Interface**
  - Built with MAXScript.
  - No Python runtime required.
  - No PySide or Qt dependency.
  - Designed to work directly inside 3ds Max.

- 🪟 **Single-Instance Interface**
  - Opening MASAR repeatedly from the toolbar is intended to reuse the existing MASAR window instead of creating multiple instances.

---

## 🎯 Why MASAR?

Large 3D projects can contain hundreds or thousands of external assets:

- Textures
- Images
- XRefs
- Scene files
- Materials
- References
- Other external project files

When assets are moved, renamed, or transferred between computers, broken paths can become a major problem.

MASAR aims to provide a simple workflow:

```text
3ds Max Project
      │
      ▼
   Scan Assets
      │
      ▼
 Review Status
      │
 ┌────┴─────┐
 ▼          ▼
Save      Relink
 │          │
 └────┬─────┘
      ▼
Package Project
      │
      ▼
Portable Project
