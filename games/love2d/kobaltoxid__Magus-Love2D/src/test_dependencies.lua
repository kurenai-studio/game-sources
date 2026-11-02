#!/usr/bin/env lua

-- Test script to verify dependencies are properly set up
-- This can be run with: lua test_dependencies.lua

print("Testing Magus-Love2D dependencies...")

-- Test bump library
local success, bump = pcall(require, 'bump.bump')
if success then
    print("✓ bump.lua library loaded successfully")
    print("  Version:", bump._VERSION or "Unknown")
    print("  URL:", bump._URL or "Unknown")
else
    print("✗ Failed to load bump.lua library")
    print("  Error:", bump)
    print("  Make sure to run: git submodule update --init --recursive")
end

-- Test STI library
local success_sti, sti = pcall(require, 'sti')
if success_sti then
    print("✓ STI (Simple Tiled Implementation) library loaded successfully")
else
    print("✗ Failed to load STI library")
    print("  Error:", sti)
end

-- Summary
if success and success_sti then
    print("\n🎉 All dependencies loaded successfully!")
    print("You can now run the game with: love .")
else
    print("\n❌ Some dependencies failed to load.")
    print("Please check the setup instructions in README.md")
end