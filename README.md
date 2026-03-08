# discourse-browser-bypass

A Discourse plugin that lets specific user-agents (or **all** browsers) bypass the "unsupported browser" interstitial page.

## The Problem

Discourse maintains a `browser_update_user_agents` site setting (default: `MSIE 6|MSIE 7|MSIE 8|MSIE 9|Xbox|PlayStation`) that forces matching browsers into a stripped-down crawler layout with an "unsupported browser" banner. On sites with `login_required` enabled, these users are completely locked out — they can't see content or reach the login page.

Some of those user-agents (e.g. PlayStation 5, Xbox Series X) ship modern WebKit/Gecko engines that are perfectly capable of running the Discourse Ember app, but the broad pattern match blocks them anyway.

## What This Plugin Does

It prepends `CrawlerDetection.show_browser_update?` with a check that can either:

1. **Selectively bypass** specific user-agents via a pipe-delimited list, or
2. **Disable the gate entirely** with a single toggle

If the user-agent would normally trigger the browser-update page, the plugin intercepts and allows it through — serving the full Ember application instead of the crawler layout.

## Installation

Add to your Discourse container's `app.yml`:

```yaml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/tonyfruzza/discourse-browser-bypass.git
```

Or in a custom Dockerfile:

```dockerfile
RUN git clone --depth 1 \
  https://github.com/tonyfruzza/discourse-browser-bypass.git \
  /var/www/discourse/plugins/discourse-browser-bypass
```

## Settings

After installation, configure in **Admin > Settings** (search "browser bypass"):

| Setting | Default | Description |
|---------|---------|-------------|
| `browser_bypass_enabled` | `true` | Master switch for the plugin |
| `browser_bypass_allow_all` | `false` | Disable the unsupported-browser gate for **all** browsers |
| `browser_update_bypass_agents` | `PlayStation 5` | Pipe-delimited user-agent fragments to selectively bypass |

### Examples

**Allow PlayStation 5 and Xbox Series X:**

```
PlayStation 5|Xbox Series
```

**Allow everything (don't block any browser):**

Enable `browser_bypass_allow_all` — the `browser_update_bypass_agents` list is ignored when this is on.

## How It Works

Discourse's request handling chain:

1. `CrawlerDetection.show_browser_update?(user_agent)` checks the UA against `browser_update_user_agents`
2. If matched → `use_crawler_layout?` returns `true` → crawler layout is served
3. With `login_required: true`, the crawler layout shows "unsupported browser" with no login option

This plugin prepends step 1 so that:

- If `browser_bypass_allow_all` is enabled → always returns `false` (no browser is "unsupported")
- Otherwise, if the UA matches `browser_update_bypass_agents` → returns `false` for that specific UA
- All other UAs behave normally (MSIE 6–9, etc. remain blocked unless explicitly bypassed)

## Compatibility

- Discourse 2.7.0+
- Tested on `discourse/discourse:2026.1.1`
