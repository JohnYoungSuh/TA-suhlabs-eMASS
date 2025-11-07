#!/usr/bin/env python3
"""
Automated Demo Video Creator for TA-securepro-eMASS
Creates a professional demo video without watermarks showing:
1. Splunk UI configuration for systemId
2. Data collection and visualization
"""

import asyncio
import time
from playwright.async_api import async_playwright
from pathlib import Path

# Configuration
SPLUNK_URL = "http://localhost:8000"
SPLUNK_USERNAME = "admin"
SPLUNK_PASSWORD = "Password123!"
DEMO_ACCOUNT_NAME = "emass_demo"
SYSTEM_ID = "55090"
BASE_URL = "http://host.docker.internal:4010"  # Mock API inside Docker
API_KEY = "demo-api-key-12345"
VIDEO_PATH = "./demo_output/emass_demo.webm"
SLOW_MO = 1000  # Slow down actions by 1 second for visibility


async def wait_and_type(page, selector, text, delay=100):
    """Type text slowly for better visibility"""
    await page.wait_for_selector(selector, state="visible")
    await page.fill(selector, "")  # Clear first
    await page.type(selector, text, delay=delay)


async def wait_for_splunk_ui_ready():
    """Wait for Splunk UI to be actually ready (not just API)"""
    import aiohttp
    print("⏳ Waiting for Splunk UI to be fully ready...")

    max_attempts = 30
    for attempt in range(max_attempts):
        try:
            async with aiohttp.ClientSession() as session:
                async with session.get(SPLUNK_URL, timeout=aiohttp.ClientTimeout(total=10)) as response:
                    if response.status == 200:
                        text = await response.text()
                        # Check if we get actual HTML, not an error page
                        if '<html' in text.lower() and 'splunk' in text.lower():
                            print("✓ Splunk UI is ready!")
                            # Extra wait to ensure everything is loaded
                            await asyncio.sleep(10)
                            return True
        except Exception as e:
            pass

        if attempt < max_attempts - 1:
            print(f"  Attempt {attempt + 1}/{max_attempts} - waiting...")
            await asyncio.sleep(5)

    print("❌ Splunk UI did not become ready in time")
    return False


async def create_demo(headless=False):
    """Create automated demo video"""
    print("🎬 Starting demo video creation...")

    # Wait for Splunk UI to be ready first
    if not await wait_for_splunk_ui_ready():
        print("❌ Splunk UI is not ready. Aborting.")
        return

    # Ensure output directory exists
    output_dir = Path("./demo_output")
    output_dir.mkdir(exist_ok=True)

    async with async_playwright() as p:
        # Launch browser with video recording
        browser = await p.chromium.launch(
            headless=headless,
            slow_mo=SLOW_MO
        )

        context = await browser.new_context(
            viewport={"width": 1920, "height": 1080},
            record_video_dir="./demo_output",
            record_video_size={"width": 1920, "height": 1080}
        )

        page = await context.new_page()

        try:
            # ===== SCENE 1: Login to Splunk =====
            print("📝 Scene 1: Logging into Splunk...")
            await page.goto(SPLUNK_URL, wait_until="networkidle", timeout=60000)
            await asyncio.sleep(3)  # Extra wait for page to settle

            # Login
            await wait_and_type(page, 'input[name="username"]', SPLUNK_USERNAME)
            await wait_and_type(page, 'input[name="password"]', SPLUNK_PASSWORD)
            await page.click('input[type="submit"]')
            await page.wait_for_load_state("networkidle")
            await asyncio.sleep(2)

            # ===== SCENE 2: Navigate to TA-securepro-eMASS Configuration =====
            print("🔧 Scene 2: Navigating to add-on configuration...")

            # Go to Apps menu
            await page.goto(f"{SPLUNK_URL}/en-US/app/TA-securepro-eMASS/configuration")
            await page.wait_for_load_state("networkidle")
            await asyncio.sleep(3)

            # ===== SCENE 3: Configure Account with System ID =====
            print("⚙️  Scene 3: Configuring eMASS account with System ID...")

            # Click on Configuration tab (should already be there)
            try:
                config_tab = await page.wait_for_selector('text=Configuration', timeout=5000)
                if config_tab:
                    await config_tab.click()
                    await asyncio.sleep(1)
            except:
                pass  # Already on configuration page

            # Click "Add" button to create new account
            add_button_selectors = [
                'button:has-text("Add")',
                'button[label="Add"]',
                'button[data-test="add"]',
                '.btn:has-text("Add")'
            ]

            for selector in add_button_selectors:
                try:
                    await page.wait_for_selector(selector, timeout=3000)
                    await page.click(selector)
                    break
                except:
                    continue

            await asyncio.sleep(2)

            # Fill in account details
            print("   - Entering account name...")
            await wait_and_type(page, 'input[name="name"]', DEMO_ACCOUNT_NAME, delay=150)
            await asyncio.sleep(1)

            print("   - Entering System ID: 55090...")
            await wait_and_type(page, 'input[name="system_id"]', SYSTEM_ID, delay=150)
            await asyncio.sleep(1)

            print("   - Entering Base URL...")
            await wait_and_type(page, 'input[name="base_url"]', BASE_URL, delay=100)
            await asyncio.sleep(1)

            print("   - Entering API Key...")
            await wait_and_type(page, 'input[name="api_key"]', API_KEY, delay=100)
            await asyncio.sleep(1)

            # Select index
            print("   - Selecting index...")
            try:
                await page.select_option('select[name="index"]', 'main')
            except:
                print("   - Index selection not required or different selector")

            await asyncio.sleep(2)

            # Save the account
            print("   - Saving account configuration...")
            save_selectors = [
                'button:has-text("Add")',
                'button:has-text("Save")',
                'button[type="submit"]',
                'button[data-test="submit"]'
            ]

            for selector in save_selectors:
                try:
                    await page.click(selector)
                    break
                except:
                    continue

            await asyncio.sleep(3)

            # ===== SCENE 4: Configure Input =====
            print("📥 Scene 4: Configuring data input...")

            # Click on Inputs tab
            try:
                await page.click('a:has-text("Inputs")')
                await asyncio.sleep(2)
            except:
                print("   - Already on Inputs or different navigation")

            # Click "Create New Input" button
            create_input_selectors = [
                'button:has-text("Create New Input")',
                'button:has-text("Add")',
                'button[data-test="add-input"]'
            ]

            for selector in create_input_selectors:
                try:
                    await page.click(selector)
                    await asyncio.sleep(2)
                    break
                except:
                    continue

            # Fill input details
            try:
                await wait_and_type(page, 'input[name="name"]', "emass_poam_collection", delay=150)
                await asyncio.sleep(1)

                # Set interval to 300 seconds (5 minutes)
                await wait_and_type(page, 'input[name="interval"]', "300", delay=150)
                await asyncio.sleep(1)

                # Select the account we just created
                await page.select_option('select[name="account"]', DEMO_ACCOUNT_NAME)
                await asyncio.sleep(2)

                # Save input
                for selector in save_selectors:
                    try:
                        await page.click(selector)
                        break
                    except:
                        continue

                await asyncio.sleep(3)
            except Exception as e:
                print(f"   - Input configuration may already exist or different UI: {e}")

            # ===== SCENE 5: View Data Collection =====
            print("📊 Scene 5: Viewing collected POA&M data...")

            # Navigate to Search & Reporting
            await page.goto(f"{SPLUNK_URL}/en-US/app/search/search")
            await page.wait_for_load_state("networkidle")
            await asyncio.sleep(2)

            # Enter search query
            search_query = 'index=main sourcetype="emass:poam" | head 10'
            search_input_selectors = [
                'textarea[data-test="search-input"]',
                'textarea.ace_text-input',
                'div[data-test="editor"] textarea',
                'textarea[name="q"]'
            ]

            for selector in search_input_selectors:
                try:
                    await page.wait_for_selector(selector, timeout=3000)
                    await page.fill(selector, search_query)
                    break
                except:
                    continue

            await asyncio.sleep(2)

            # Click search button
            search_button_selectors = [
                'button[aria-label="Search"]',
                'button[data-test="search-button"]',
                'button:has-text("Search")',
                '.search-button'
            ]

            for selector in search_button_selectors:
                try:
                    await page.click(selector)
                    break
                except:
                    continue

            # Wait for results
            await page.wait_for_load_state("networkidle")
            await asyncio.sleep(5)

            # ===== SCENE 6: Show Data Details =====
            print("🔍 Scene 6: Showing POA&M details...")

            # Try to expand first event to show details
            try:
                expand_selectors = [
                    'button[aria-label="Show event details"]',
                    '.event-toggle',
                    'button:has-text(">")'
                ]

                for selector in expand_selectors:
                    try:
                        buttons = await page.query_selector_all(selector)
                        if buttons and len(buttons) > 0:
                            await buttons[0].click()
                            break
                    except:
                        continue

                await asyncio.sleep(3)
            except Exception as e:
                print(f"   - Could not expand event details: {e}")

            # ===== Final Scene: Hold on results =====
            print("✨ Final scene: Displaying results...")
            await asyncio.sleep(5)

            print("✅ Demo recording complete!")

        except Exception as e:
            print(f"❌ Error during demo: {e}")
            import traceback
            traceback.print_exc()

        finally:
            # Close browser (this finalizes the video)
            await context.close()
            await browser.close()

            # Rename video to our desired name
            import os
            video_files = list(output_dir.glob("*.webm"))
            if video_files:
                os.rename(video_files[0], VIDEO_PATH)
                print(f"\n🎥 Demo video saved to: {VIDEO_PATH}")
                print(f"   File size: {Path(VIDEO_PATH).stat().st_size / 1024 / 1024:.2f} MB")
            else:
                print("⚠️  No video file found")


async def main():
    """Main entry point"""
    print("=" * 60)
    print("  TA-securepro-eMASS Automated Demo Video Creator")
    print("=" * 60)
    print()
    print("Prerequisites:")
    print("  ✓ Splunk running on http://localhost:8000")
    print("  ✓ Mock eMASS API running on http://localhost:4010")
    print("  ✓ TA-securepro-eMASS installed in Splunk")
    print()
    print("This will create a professional demo video showing:")
    print("  1. Splunk UI configuration")
    print("  2. System ID setup (55090)")
    print("  3. Data collection from eMASS API")
    print("  4. POA&M data visualization")
    print()

    # Ask for headless mode
    import sys
    headless = "--headless" in sys.argv

    if not headless:
        print("Running in visible mode (you can watch the demo being created)")
        print("Tip: Use --headless flag for background recording")
    else:
        print("Running in headless mode (background recording)")

    print()
    input("Press Enter to start recording... ")
    print()

    await create_demo(headless=headless)


if __name__ == "__main__":
    asyncio.run(main())
