#!/usr/bin/env python3
"""
Automated Demo Video Creator for TA-securepro-eMASS (Selenium version)
Creates a professional demo video without watermarks showing:
1. Splunk UI configuration for systemId
2. Data collection and visualization
"""

import time
import cv2
import numpy as np
import io
from PIL import Image
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import Select
from pathlib import Path
import threading

# Configuration
SPLUNK_URL = "http://localhost:8000"
SPLUNK_USERNAME = "admin"
SPLUNK_PASSWORD = "Password123!"
DEMO_ACCOUNT_NAME = "emass_demo"
SYSTEM_ID = "55090"
BASE_URL = "http://host.docker.internal:4010"
API_KEY = "f32516cc-57d3-43f5-9e16-8f86780a4cce"
USER_UID = "1647389405"
VIDEO_PATH = "./demo_output/emass_demo.avi"
FPS = 20


class ScreenRecorder:
    """Records browser screenshots to video file using OpenCV"""

    def __init__(self, output_path, driver, fps=20):
        self.output_path = output_path
        self.driver = driver
        self.fps = fps
        self.recording = False
        self.writer = None
        self.thread = None

    def start(self):
        """Start recording"""
        self.recording = True
        self.thread = threading.Thread(target=self._record)
        self.thread.start()
        print("🎥 Screen recording started...")

    def _record(self):
        """Recording loop"""
        # Get browser window size from first screenshot
        screenshot_png = self.driver.get_screenshot_as_png()
        screenshot = Image.open(io.BytesIO(screenshot_png))
        width, height = screenshot.size

        # Create video writer
        fourcc = cv2.VideoWriter_fourcc(*'XVID')
        self.writer = cv2.VideoWriter(
            self.output_path,
            fourcc,
            self.fps,
            (width, height)
        )

        while self.recording:
            try:
                # Capture browser screenshot
                screenshot_png = self.driver.get_screenshot_as_png()
                screenshot = Image.open(io.BytesIO(screenshot_png))
                frame = np.array(screenshot)
                frame = cv2.cvtColor(frame, cv2.COLOR_RGB2BGR)

                # Write frame
                self.writer.write(frame)

                # Control frame rate
                time.sleep(1/self.fps)
            except Exception as e:
                print(f"⚠️  Screenshot capture error: {e}")
                time.sleep(1/self.fps)

    def stop(self):
        """Stop recording"""
        self.recording = False
        if self.thread:
            self.thread.join()
        if self.writer:
            self.writer.release()
        print("✅ Screen recording stopped")


def wait_and_type(driver, selector, text, by=By.NAME, delay=0.1):
    """Type text slowly for better visibility"""
    element = WebDriverWait(driver, 30).until(
        EC.presence_of_element_located((by, selector))
    )
    element.clear()
    for char in text:
        element.send_keys(char)
        time.sleep(delay)


def take_screenshot(driver, name):
    """Take a screenshot for debugging"""
    try:
        screenshot_path = f"./demo_output/debug_{name}.png"
        driver.save_screenshot(screenshot_path)
        print(f"  📸 Screenshot saved: {screenshot_path}")
    except Exception as e:
        print(f"  ⚠️  Could not take screenshot: {e}")


def create_demo(headless=False):
    """Create automated demo video using Selenium"""
    print("🎬 Starting demo video creation...")

    # Ensure output directory exists
    output_dir = Path("./demo_output")
    output_dir.mkdir(exist_ok=True)

    # Setup Chrome options
    chrome_options = Options()
    if headless:
        chrome_options.add_argument('--headless')
    chrome_options.add_argument('--no-sandbox')
    chrome_options.add_argument('--disable-dev-shm-usage')
    chrome_options.add_argument('--window-size=1920,1080')

    # Initialize WebDriver
    driver = webdriver.Chrome(options=chrome_options)
    driver.maximize_window()

    # Start screen recorder (must be after driver is created)
    recorder = ScreenRecorder(VIDEO_PATH, driver, fps=FPS)
    recorder.start()
    time.sleep(2)  # Give recorder time to initialize

    try:
        # ===== SCENE 1: Login to Splunk =====
        print("📝 Scene 1: Logging into Splunk...")
        driver.get(SPLUNK_URL)
        time.sleep(3)
        take_screenshot(driver, "01_login_page")

        # Login
        wait_and_type(driver, "username", SPLUNK_USERNAME)
        wait_and_type(driver, "password", SPLUNK_PASSWORD)

        submit_button = driver.find_element(By.CSS_SELECTOR, 'input[type="submit"]')
        submit_button.click()
        time.sleep(5)

        # ===== SCENE 2: Navigate to TA-securepro-eMASS Configuration =====
        print("🔧 Scene 2: Navigating to add-on configuration...")
        driver.get(f"{SPLUNK_URL}/en-US/app/TA-securepro-eMASS/configuration")
        time.sleep(5)
        take_screenshot(driver, "02_configuration_page")

        # ===== SCENE 3: Configure Account with System ID =====
        print("⚙️  Scene 3: Configuring eMASS account with System ID...")
        time.sleep(2)

        # Click "Add" button for account
        try:
            add_button = WebDriverWait(driver, 10).until(
                EC.element_to_be_clickable((By.XPATH, "//button[contains(text(), 'Add')]"))
            )
            add_button.click()
            time.sleep(3)
            take_screenshot(driver, "03_add_account_modal")
        except Exception as e:
            print(f"   ⚠️  Could not find Add button: {e}")
            take_screenshot(driver, "03_add_button_not_found")

        # Fill in account details
        print("   - Entering account name...")
        try:
            wait_and_type(driver, "name", DEMO_ACCOUNT_NAME, delay=0.15)
            time.sleep(1)

            print("   - Entering System ID: 55090...")
            wait_and_type(driver, "system_id", SYSTEM_ID, delay=0.15)
            time.sleep(1)

            print("   - Entering Base URL...")
            wait_and_type(driver, "base_url", BASE_URL, delay=0.1)
            time.sleep(1)

            print("   - Entering API Key...")
            wait_and_type(driver, "api_key", API_KEY, delay=0.1)
            time.sleep(1)

            print("   - Entering User UID...")
            wait_and_type(driver, "user_uid", USER_UID, delay=0.1)
            time.sleep(1)

            # Select index
            print("   - Selecting index...")
            try:
                index_select = Select(driver.find_element(By.NAME, "index"))
                index_select.select_by_value("main")
            except:
                print("   - Index selection not required or different selector")

            time.sleep(2)
            take_screenshot(driver, "04_account_filled")

            # Save the account
            print("   - Saving account configuration...")
            save_button = driver.find_element(By.XPATH, "//button[contains(text(), 'Add') or contains(text(), 'Save')]")
            save_button.click()
            time.sleep(5)

        except Exception as e:
            print(f"   ❌ Error filling account details: {e}")
            take_screenshot(driver, "05_account_error")

        # ===== SCENE 4: Navigate to Inputs =====
        print("📥 Scene 4: Navigating to Inputs page...")
        driver.get(f"{SPLUNK_URL}/en-US/app/TA-securepro-eMASS/inputs")
        time.sleep(5)
        take_screenshot(driver, "06_inputs_page")

        # Click "Create New Input"
        try:
            create_button = WebDriverWait(driver, 10).until(
                EC.element_to_be_clickable((By.XPATH, "//button[contains(text(), 'Create') or contains(text(), 'Add')]"))
            )
            create_button.click()
            time.sleep(3)
            take_screenshot(driver, "07_create_input_modal")

            # Fill input details
            print("   - Entering input name...")
            wait_and_type(driver, "name", "emass_poam_collection", delay=0.15)
            time.sleep(1)

            print("   - Selecting account...")
            account_select = Select(driver.find_element(By.NAME, "account"))
            account_select.select_by_value(DEMO_ACCOUNT_NAME)
            time.sleep(2)

            print("   - Setting interval...")
            wait_and_type(driver, "interval", "300", delay=0.15)
            time.sleep(1)

            print("   - Selecting index...")
            index_select = Select(driver.find_element(By.NAME, "index"))
            index_select.select_by_value("main")
            time.sleep(2)

            take_screenshot(driver, "08_input_filled")

            # Save input
            save_button = driver.find_element(By.XPATH, "//button[contains(text(), 'Add') or contains(text(), 'Save')]")
            save_button.click()
            time.sleep(5)

        except Exception as e:
            print(f"   ❌ Error creating input: {e}")
            take_screenshot(driver, "09_input_error")

        # ===== SCENE 5: View Data Collection =====
        print("📊 Scene 5: Viewing collected POA&M data...")
        driver.get(f"{SPLUNK_URL}/en-US/app/search/search")
        time.sleep(3)

        # Enter search query
        search_query = 'index=main sourcetype="emass:poam" | head 10'
        try:
            search_input = WebDriverWait(driver, 10).until(
                EC.presence_of_element_located((By.CSS_SELECTOR, 'textarea[data-test="search-input"]'))
            )
            search_input.send_keys(search_query)
            time.sleep(2)

            # Click search button
            search_button = driver.find_element(By.CSS_SELECTOR, 'button[aria-label="Search"]')
            search_button.click()
            time.sleep(7)
            take_screenshot(driver, "10_search_results")

            # Try to expand first event
            try:
                expand_button = driver.find_element(By.CSS_SELECTOR, 'button[aria-label="Show event details"]')
                expand_button.click()
                time.sleep(3)
                take_screenshot(driver, "11_event_details")
            except:
                print("   - Could not expand event details")

        except Exception as e:
            print(f"   ❌ Error searching data: {e}")
            take_screenshot(driver, "12_search_error")

        # Hold on results
        print("✨ Final scene: Displaying results...")
        time.sleep(5)

        print("✅ Demo recording complete!")

    except Exception as e:
        print(f"❌ Error during demo: {e}")
        import traceback
        traceback.print_exc()
        take_screenshot(driver, "99_fatal_error")

    finally:
        # Cleanup
        time.sleep(2)
        driver.quit()
        time.sleep(1)
        recorder.stop()

        print(f"\n🎥 Demo video saved to: {VIDEO_PATH}")
        if Path(VIDEO_PATH).exists():
            size_mb = Path(VIDEO_PATH).stat().st_size / 1024 / 1024
            print(f"   File size: {size_mb:.2f} MB")


def main():
    """Main entry point"""
    print("=" * 60)
    print("  TA-securepro-eMASS Automated Demo Video Creator")
    print("  (Selenium version)")
    print("=" * 60)
    print()
    print("Prerequisites:")
    print("  ✓ Splunk running on http://localhost:8000")
    print("  ✓ Mock eMASS API running on http://localhost:4010")
    print("  ✓ TA-securepro-eMASS installed in Splunk")
    print("  ✓ Chrome/Chromium browser installed")
    print()
    print("This will create a professional demo video showing:")
    print("  1. Splunk UI configuration")
    print("  2. System ID setup (55090)")
    print("  3. Data collection from eMASS API")
    print("  4. POA&M data visualization")
    print()

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

    create_demo(headless=headless)


if __name__ == "__main__":
    main()
