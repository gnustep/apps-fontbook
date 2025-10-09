# GNUstep Font Book

A lightweight font management application for the GNUstep environment, inspired by **Font Book.app** on macOS.  
This app provides a graphical interface to preview, organize, and activate/deactivate fonts across your GNUstep desktop.

---

## Features

- Browse installed system fonts
- Preview fonts with custom text and sizes
- Organize fonts into collections (e.g., serif, sans-serif, monospace)
- Enable or disable fonts without removing them from the system
- Detect duplicate or corrupted font files
- Integrates with GNUstep look and feel

---

## Screenshots

<img width="907" height="768" alt="font_book_app" src="https://github.com/user-attachments/assets/81f2c0de-ec48-450d-875e-71acec8ab379" />

---

## Requirements

- [GNUstep](https://www.gnustep.org/)  
- FreeType (for font rendering)  
- A modern C compiler (GCC or Clang)  
- libart or Cairo backend (depending on your GNUstep setup)

---

## Installation

Clone the repository:

```bash
git clone https://github.com/gnustep/apps-fontbook.git
cd apps-fontbook
buildtool
