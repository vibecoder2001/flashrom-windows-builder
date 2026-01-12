# 🔥 flashrom for Windows (unofficial)

This repo builds **flashrom** for **Windows** using **MSYS2 (MINGW64)** and publishes a **portable zip** every time the submodule is updated or you push.

Each build includes:
- 🧰 `flashrom.exe`
- 🔌 `libusb-1.0.dll`
- 🧾 `FLASHROM_VERSION.txt` (commit + nearest tag + build time)
- 📜 `COPYING` (flashrom license, if present)

---

## 📥 Clone

```bash
git clone --recurse-submodules <your-repo-url>
````

If you forgot `--recurse-submodules`:

```bash
git submodule update --init --recursive
```

---

## 🔄 Nightly upstream tracking

A GitHub Actions workflow runs every night 🌙 and:

1. Fetches the latest commit from upstream **flashrom**
2. Pins the `flashrom` submodule to that commit
3. Pushes the update to
   **`autobump/flashrom`**
4. Triggers a Windows build 🏗️

This means you always get builds of the **latest upstream flashrom commit**, not just tagged releases.

---

## 📦 Artifacts

Every build produces a zip like:

```
flashrom-untagged-1a2b3c4d5e6f-windows-x64.zip
```

(or with a tag if one exists)

Inside you’ll find everything you need to run flashrom on Windows without installing MSYS2.

---

## 🔌 USB driver setup (important!)

Flashrom’s USB programmers (including CR50 / raiden_debug_spi) require the device interface to be bound to **WinUSB**.

Use **Zadig** to bind the correct interface to:

```
WinUSB
```

Without this, libusb can’t talk to the device ❌

---

## ⚠️ CR50 / CCD notes

If you are using CR50 / SuzyQ / raiden_debug_spi:

* 🔓 CCD must allow `FlashAP` / `FlashEC`
* 🔒 Write-protect must be overridden if you want to write
* ❗ If flashrom says *“SPI bridge disabled”*, it’s a CCD/WP issue — not Windows

---

## 🛠️ What this repo gives you

* 🧩 Upstream-tracking flashrom builds
* 🪟 Native Windows executables
* 📅 Nightly updates
* 📦 Ready-to-run zip files
* 🧪 Ideal for CR50, SuzyQ, Servo, and other libusb programmers

---

Have fun flashing responsibly 🔥💾
