# Unsigned App FAQ: Understanding MindMic Security

This FAQ explains why MindMic shows security warnings and how to safely install unsigned applications.

## What is an Unsigned Application?

### Definition
An **unsigned application** is software that hasn't been registered with Apple's Developer Program. This means Apple hasn't verified the developer's identity, but the application itself can still be perfectly safe and functional.

### Why MindMic is Unsigned

MindMic is distributed unsigned to avoid the **$99/year Apple Developer Program fee**. This allows:
- **Free distribution** to all users
- **No paywall** for access to the software
- **Open source transparency** - code is publicly reviewable

## Security Warnings Explained

### What You'll See

When you first try to open MindMic, macOS will display:

> *"MindMic.app can't be opened because Apple cannot check it for malicious software."*
>
> *"This software needs to be updated. Contact its developer to find out if a version of this software is available that's compatible with this Mac."*

### What This Means

- ✅ **Normal behavior** for unsigned applications
- ✅ **Not an indication of malware**
- ✅ **macOS protection feature** working as designed
- ❌ **Not a sign that the app is dangerous**

### Why macOS Shows These Warnings

macOS uses **Gatekeeper** to protect users from potentially harmful software. When an app is unsigned:
1. macOS can't verify the developer's identity
2. It shows a warning to be cautious
3. Users must explicitly approve the application

## How to Safely Install Unsigned Apps

### Method 1: System Settings (Recommended)

1. Try to open MindMic (you'll see the warning). Click **Done**
2. Go to **System Settings → Privacy & Security**
3. Scroll to the security section about MindMic
4. Click **"Open Anyway"** and confirm with your password
5. Grant permissions when prompted

On macOS 15 (Sequoia) and later, right-click → Open no longer bypasses the check.

### Method 2: Terminal (if macOS says the app is "damaged")

```bash
xattr -dr com.apple.quarantine /Applications/MindMic.app
```

### After First Launch

Once you successfully open MindMic using either method:
- ✅ macOS remembers your choice
- ✅ You can launch normally (double-click) in the future
- ✅ No more warnings for this application

## Security Verification

### How to Verify MindMic is Safe

**1. Source Code Review**
- Visit: https://github.com/rohitctrl/mindmic.app
- All code is publicly available
- Community can review and audit the code

**2. Checksum Verification**
```bash
# Verify your download matches the official release
shasum -a 256 ~/Downloads/MindMic-2.0-unsigned.dmg
```

**3. Community Trust**
- Check GitHub issues and discussions
- See what other users report
- Look at the project's activity and maintenance

**4. Permission Analysis**
MindMic only requests permissions it needs:
- 🎤 **Microphone**: For voice recording
- 🖥️ **Screen Recording**: For Power Mode context
- 🌐 **Network**: For AI services
- 📁 **Files**: For saving transcriptions

### Red Flags to Watch For

**Legitimate unsigned apps like MindMic:**
- ✅ Open source code
- ✅ Active development
- ✅ Clear documentation
- ✅ Reasonable permission requests
- ✅ Community engagement

**Suspicious apps (red flags):**
- ❌ No source code available
- ❌ Excessive permission requests
- ❌ No developer information
- ❌ Poor documentation
- ❌ Negative community feedback

## macOS Security Model

### How Gatekeeper Works

```
User tries to open app
    ↓
Is app from App Store?
    ↓ No
Is app from identified developer?
    ↓ No (unsigned)
Show warning → User must approve
```

### Protection Levels

1. **App Store** - Most restricted, fully verified
2. **Identified Developer** - Verified developer, notarized apps
3. **Unsigned** - No verification, user approval required

### Why This System Exists

- **Protects users** from unknown software
- **Prevents malware** from running automatically
- **Gives users control** over what runs on their Mac
- **Encourages developer accountability**

## Best Practices for Unsigned Apps

### Before Installing

1. **Source verification**: Check if code is open source
2. **Community feedback**: Look for user reviews and issues
3. **Developer transparency**: Clear documentation and contact info
4. **Permission review**: Ensure requested permissions make sense

### After Installation

1. **Monitor behavior**: Watch for unusual activity
2. **Keep updated**: Install new versions when available
3. **Permission management**: Review app permissions regularly
4. **Report issues**: Help the community by reporting bugs

### General Security

1. **Backup regularly**: Keep your data safe
2. **Use antivirus**: Consider additional security software
3. **Stay updated**: Keep macOS and apps current
4. **Be skeptical**: Verify software before installing

## Common Misconceptions

### Myth: "Unsigned means malicious"

**Reality**: Many legitimate applications are unsigned due to:
- Cost of developer programs
- Independent developer limitations
- Philosophical opposition to app store policies
- Distribution method preferences

### Myth: "App Store apps are always safer"

**Reality**: While App Store apps are verified, they can still:
- Collect excessive user data
- Have security vulnerabilities
- Engage in questionable practices
- Be abandoned by developers

### Myth: "I should only use signed apps"

**Reality**: Open source unsigned apps can be:
- **More transparent** than commercial software
- **More secure** due to community review
- **More trustworthy** than unknown commercial apps
- **Better maintained** than some paid alternatives

## MindMic Specifics

### Why MindMic Chose Unsigned Distribution

1. **Accessibility**: Free for all users
2. **Independence**: No Apple revenue sharing
3. **Transparency**: Open source development
4. **Flexibility**: Direct distribution control
5. **Community**: Direct relationship with users

### MindMic Security Practices

- ✅ **Open source**: All code publicly available
- ✅ **Minimal permissions**: Only requests what's needed
- ✅ **Local processing**: Core features work offline
- ✅ **No tracking**: No user analytics or telemetry
- ✅ **Community driven**: Issues and feedback public

### What MindMic Does With Permissions

- **Microphone**: Records audio for transcription
- **Screen Recording**: Captures active application context for Power Mode
- **Network**: Communicates with AI services for enhancement
- **File System**: Saves transcriptions and reads audio files
- **Apple Events**: Integrates with browsers and system apps

## Getting Help

### If You're Still Concerned

1. **Review the code**: https://github.com/rohitctrl/mindmic.app
2. **Check issues**: See what problems users report
3. **Ask questions**: Use GitHub discussions
4. **Wait and see**: Monitor the project before installing

### Alternative Options

If you're uncomfortable with unsigned apps:
1. **Use similar paid apps** from the App Store
2. **Build from source** yourself
3. **Wait for potential signed distribution** in the future
4. **Use web-based alternatives**

### Reporting Security Issues

If you find security concerns with MindMic:
1. **File an issue**: https://github.com/rohitctrl/mindmic.app/issues
2. **Email privately**: If it's a sensitive security issue
3. **Be specific**: Include details and reproduction steps
4. **Be constructive**: Help improve the project

## Conclusion

Unsigned applications like MindMic can be just as safe as signed applications when:
- The source code is open and reviewable
- The developer is transparent and responsive
- The community is active and engaged
- Permissions are reasonable and necessary

The security warnings you see are **macOS protecting you by default**, which is a good thing! By following the safe installation practices outlined above, you can confidently use MindMic while maintaining your security.

---

**Remember**: In security, the most important tool is your own judgment. Take time to verify software, understand the risks, and make informed decisions about what you install on your computer.