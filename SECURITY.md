# Security Policy

## Supported Versions

We regularly maintain the latest stable release of reader-app. Only the `main` branch and the latest releases are currently supported with security updates.

## Reporting a Vulnerability

If you discover a security vulnerability in reader-app, please **DO NOT create a public GitHub issue**. Instead, report it privately to maintain the safety of our users.

- **Preferred Contact:**
- 
- Alternatively, you may use GitHub's [Private Vulnerability Reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing/privately-reporting-a-security-vulnerability).

Include the following in your email:
- Description of the vulnerability
- Steps to reproduce or exploit (if applicable)
- Suggested mitigation (optional)
- Your name and/or GitHub username (optional, for credit)

We aim to respond within **72 hours** and will update you throughout our investigation and remediation process.

## Vulnerability Handling & Disclosure

- We will investigate all reports promptly and keep the reporter updated on the status.
- Once verified, we will issue a patch and prepare a new release.
- We will acknowledge the reporter unless anonymity is requested.
- Public disclosure will occur after a patch is available or after a coordinated timeline (usually no more than 30 days after acknowledgement).

## Scope

This policy applies to:
- reader-app source code in this repository, including Flutter/Dart code and dependency configurations (`pubspec.yaml`)
- Configuration files or scripts related to deployment and build.

**Out-of-Scope** includes:
- Third-party sites accessed via WebView
- Vulnerabilities in Flutter, libraries, or WebView itself (report these upstream)
- Social engineering attacks against our maintainers or users

## Recommendations for Users

- Always use the latest official release of reader-app.
- Check the [releases](https://github.com/anjastslt23/reading-app.git) page for security updates.
- Review and audit any modifications you make or third-party forks you use.

## Dependencies and Supply Chain Security

We depend on [Flutter](https://flutter.dev) and related publicly available packages.  
We regularly audit our dependencies for vulnerabilities and keep them updated.
If you discover vulnerabilities in our dependent packages, report them to the respective upstream maintainers.

## PGP/GPG Key

We are planning to sign future releases and advisories with a public PGP/GPG key, which will be published in the repository.

---

Thank you for helping us keep reader-app and its users safe!
