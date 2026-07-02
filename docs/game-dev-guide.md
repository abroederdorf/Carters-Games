# Build Your Own Game App: A Guide for Young Game Makers

> **Who this is for:** Kids age 10–15 who want to build a real game that other people can actually play — not just a school project, but something you can share a link to. No experience required. An adult helping with some of the setup steps is totally normal and expected.
>
> **Real example used throughout:** [Carter's Games](https://cartersgames.alpinealicia.com) — a real app built by a parent and kid together, with a fishing game and a hidden-objects game. We'll use it as a reference so you can see what "done" looks like.

---

## The Big Picture

Here's what you'll build and the path to get there:

```
Your idea → Design → Build in Godot → Create art → Test it → Ship it
```

This isn't a weekend project — expect it to take **weeks** depending on how ambitious your game is. That's normal. Real games take time. The good news: you'll have something playable after just a day or two, and then you keep making it better.

---

## Chapter 1: Come Up With Your Idea

The best first game is **one mechanic, kept simple.** Not "a game like Minecraft" — more like "tap on fish to catch them" or "find hidden objects in a busy picture."

### Questions to ask yourself

- What's one thing that would be fun to do over and over?
- Is there a game you already love that you could make a simpler version of?

### How Carter's Games started

The idea for the fishing game was: *"What if you could cast a line and catch a fish as they swim by?"* That's it. One sentence. The first version had no score, no music, no levels — just a line that dropped and fish that swam. That was enough to know if it was fun.

---

## Chapter 2: Your Toolbox

Here's everything you'll use and what it costs. Almost all of it is free.

| Tool | What it does | Cost |
|------|-------------|------|
| [Godot](https://godotengine.org) | The game engine — where you build and run your game | Free |
| [GitHub](https://github.com) | Saves your work and lets you deploy it | Free |
| [GitHub Pages](https://pages.github.com) | Hosts your game on the web for free | Free |
| [itch.io](https://itch.io) | Game hosting site where you can publish your game | Free |
| [Gemini](https://gemini.google.com) | AI assistant AND image generator — use it for planning, coding help, and creating all your game art | Free tier available |
| [Claude](https://claude.ai) | AI assistant — great for planning, writing code, and working through problems | Free tier available |
| [Claude Code](https://claude.ai/code) | Claude that runs on your computer and builds the game for you directly | Free tier available |
| [Cursor](https://cursor.com) | AI-powered code editor — visual alternative to Claude Code | Free tier available |

---

## Chapter 3: Set Up Your Workspace

> **Adult note:** This chapter involves creating accounts and installing software. It's a good place to help out.

### Step 1: Create a GitHub account

Go to [github.com](https://github.com) and sign up. GitHub is where your code will live. Think of it like Google Drive, but for code — it tracks every change you make and lets you go back in time if something breaks.

### Step 2: Install Godot

Go to [godotengine.org](https://godotengine.org) and download **Godot 4** (the current version). It's a single app — no complicated install. On Mac, drag it to Applications. On Windows, right-click the downloaded folder, choose **Extract All**, and select where you want to keep the Godot application (like your Desktop or Documents). Open the extracted folder and run Godot from there. Do not double-click inside the zip folder, or Godot will run into errors!

### Step 3: Create your first project

Open Godot and click **New Project**. Pick a folder, give it a name, and click **Create & Edit**. You're in.

### Step 4: Meet your AI helper

You'll be working with AI constantly throughout this process — not just to answer questions, but to help you plan, write code, and solve problems. The two best options are:

- **[Claude](https://claude.ai)** (by Anthropic) — great for planning, reasoning through problems, and writing code. Has a free tier at claude.ai.
- **[Gemini](https://gemini.google.com)** (by Google) — also excellent, especially if you're already using Google tools. Free at gemini.google.com.

Either one works. The key is knowing **how to talk to them.** We'll show you example prompts throughout this guide.

**Try this right now:**
> *"I just installed Godot 4 and I'm making my first game. How should I get started?"*

> **Free tier limits:** Both Claude and Gemini have free tiers, but they limit how many messages you can send per day. When you hit a limit on one, just switch to the other and keep going. Having accounts on both means you're rarely blocked for long.

### Step 5: Choose Where to Work with AI

There are a few different ways to interact with AI while building your game. Pick whichever feels most comfortable — they all work.

**Option 1: Claude Code or Gemini CLI (most powerful)**

These are AI tools that run in a **terminal** — a text window where you type commands. You chat with AI just like a conversation, and it writes files, runs your game, and manages git all by itself. You never touch code.

- **Claude Code** — install at [claude.ai/code](https://claude.ai/code)
- **Gemini CLI** — Google's equivalent; install by running `npm install -g @google/gemini-cli` in your terminal (AI can walk you through this)

To open a terminal:
- **Mac:** use the built-in **Terminal** app, or download [iTerm2](https://iterm2.com) for a nicer experience
- **Windows:** use **Windows Terminal** (free from the Microsoft Store)

> **Adult note:** Getting Claude Code or Gemini CLI set up takes about 10 minutes. The terminal looks intimidating but becomes second nature quickly. If it's too much friction to start, try Cursor first.

**Option 2: Cursor (most visual)**

[Cursor](https://cursor.com) is a code editor with AI built right in. You can see your project files and chat with AI in a sidebar — it edits the files directly, similar to Claude Code but in a visual interface. Good if the terminal feels uncomfortable. Free tier available.

**Option 3: Web chat (for planning only)**

Claude and Gemini on the web (claude.ai / gemini.google.com) are great for the planning phase. For actually building, they'll give you code you'd have to paste in yourself — that's why Claude Code, Gemini CLI, or Cursor are better for the build phases.

---

## Chapter 4: Plan Your Game with AI

Don't plan your game alone. AI is an excellent co-designer — and the more you tell it upfront, the better your plan will be.

### Step 1: The Brain Dump

Open a new conversation with Claude ([claude.ai](https://claude.ai)) or Gemini ([gemini.google.com](https://gemini.google.com)). Don't worry about being organized or having everything figured out. Just write down everything you know about your game idea — even if it's messy or incomplete. The more you give the AI to work with, the better.

**Example brain dump:**

> *"I want to make a game for kids. The idea is a fishing game where you tap to cast your line into the water. Fish swim by at different speeds and you have to tap them to catch them. I want a timer and some kind of score. Maybe different types of fish that are worth different points? I'm not sure if there should be levels or just one endless mode. I also thought it would be cool to have a shark that you have to avoid. I want it to run on a tablet. I'm going to build it in Godot 4. Can you help me design this game?"*

That's it. Messy, uncertain, incomplete — totally fine. AI's job is to help you fill in the gaps.

### Step 2: Let AI Ask You Questions

After your brain dump, a good AI won't immediately write a plan — it'll ask you questions to understand what you're building. Answer them as best you can. If you don't know, say so. The AI can suggest options.

You might get questions like:
- *"When the timer runs out, does the game end immediately, or does the player get to finish their current cast?"*
- *"Should the game save your high score, or start fresh every time?"*
- *"Do you want the fish to look realistic or cartoon-style?"*

These questions turn a fuzzy idea into a concrete plan. Don't skip this step — it saves a lot of backtracking later.

### Step 3: Use Plan Mode

Before AI writes any code, ask it to produce a **plan** first. If you jump straight to code, you end up with something you don't fully understand and can't easily change.

**On Claude or Gemini (web)**, ask explicitly:

> *"Before we write any code, can you write a complete game design document? Include: the core gameplay loop, all the screens in the game, what data needs to be saved, and a list of features broken into phases — what to build first, second, and so on."*

**Using Claude Code** (a more advanced tool — the adult helping you may have this installed): there's a built-in feature called **Plan Mode**. When you describe what you want to build, Claude proposes a full written plan and waits for your approval before doing anything. You can edit the plan, push back on ideas, or ask for alternatives — only when you say "looks good" does it start writing code.

> **Adult note:** Claude Code is a command-line tool that lets Claude directly write and edit code files on your computer. It's more powerful than the web interface and worth exploring as the project grows. See [claude.ai/code](https://claude.ai/code) to get started.

### Step 4: Review and Push Back

Read through the plan AI produces. At this stage it's much easier to change your mind than after code has been written. Things to check:

- Does the core gameplay sound fun when you read it back?
- Is anything missing that you care about?
- Does anything seem more complicated than you need right now?

Push back freely — this is a conversation, not a one-way street:

> *"I don't want lives — let's just use the timer."*
> *"Can we add a leaderboard that saves the top 5 scores?"*
> *"Phase 1 seems too big. Can you split it into smaller steps?"*

Keep going until the plan feels right.

### Step 5: Get a Phase Breakdown

Ask AI to break the work into **phases** — concrete milestones where each one produces something you can actually play and test. A good phase breakdown for a fishing game might look like:

| Phase | What you'll have when it's done |
|-------|--------------------------------|
| 1 | Fish swim across the screen. Tap one and it disappears. That's it. |
| 2 | A timer counts down. Score goes up per fish caught. Game over screen shows final score. |
| 3 | Multiple fish types with different speeds and point values. |
| 4 | A shark appears occasionally — tapping it ends the game early. |
| 5 | Main menu, high score leaderboard, sound effects, polish. |

Each phase gives you something working and testable. You'll find out early whether the core idea is actually fun — before you've built the fancy parts.

**You don't need every phase figured out before you start.** Give AI everything you have now and begin. You can always add more later.

---

## Chapter 5: Build Your Game with AI

With your plan in hand, you're ready to start building. Here's the key mindset: **you are the creative director, and AI is the developer.** Your job is to describe what you want clearly. AI writes the code. 

Use whichever tool you set up in Chapter 3 — Claude Code, Gemini CLI, or Cursor. They all work the same way for building: you describe what you want, AI builds it. No pasting code, no touching files.

A quick orientation on Godot's structure, because you'll hear these words a lot:
- A **Node** is one building block — an image on screen, a sound, a timer, a collision area.
- A **Scene** is a group of nodes that work together — like a fish character, a menu, or a level.

You don't need to deeply understand these. When something is confusing, just ask AI.

### Step 1: Hand AI Your Plan and Start Phase 1

Give Claude Code the full context upfront — your game plan and what you're building first. The more context it has, the better decisions it makes throughout the project:

> *"I'm building a game in Godot 4 using GDScript. Here's my full game plan: [paste your plan from Chapter 4]. Let's start with Phase 1: fish swim across the screen and you can tap them to make them disappear. Please set up the project structure and implement Phase 1."*

Claude Code will create the files, write the scripts, and set everything up. You don't need to touch the code — just watch what it's doing and ask questions if something is unclear.

### Step 2: Test It and Describe What's Wrong

Press **Play** in Godot (the triangle button, top-right) to test what AI built. Something probably won't feel right the first time — that's completely normal.

When something's off, describe it in plain language:

> *"The fish swims off the right side of the screen instead of bouncing back. Can you fix that?"*

> *"The tap isn't registering on mobile — it works with a mouse click but not a finger tap. What's wrong?"*

You don't need to understand the code or find the bug yourself. Just describe what you see and what you expected.

### Step 3: Move to the Next Phase

Once a phase works and feels good to play, move on:

> *"Phase 1 is done — fish swim and I can tap them. Now let's build Phase 2: a 60-second countdown timer, a score that increases when I catch a fish, and a game over screen showing the final score."*

Repeat for each phase. Your game grows from something simple into something real, one working piece at a time.

### Start a Fresh Conversation for Each Phase

AI gets slower and less reliable as a conversation grows very long. A simple rule: **when you finish one phase and start the next, open a fresh conversation.** Paste your game design document at the top so AI has full context — that's all it needs. You're not losing anything; you're giving AI a clean slate to work from.

> *"Here's my game design document: [paste plan]. We've completed Phases 1 and 2. Now let's build Phase 3: [describe it]."*

---

## Chapter 6: Create Your Art with AI

You don't need to be an artist. Use Gemini — on the web at [gemini.google.com](https://gemini.google.com) or the Gemini app on your phone — to generate all your game art. Both item images and full background scenes can be created right there, no separate tools needed.

### Generating item images

Use Gemini's image generation feature for individual things: a fish, a fishing rod, a bear, a tent. The key is a prompt formula that keeps items clean and consistent:

```
Isolated on white background, [describe the item], [view angle], 
thick black outlines, vibrant colors, children's cartoon image.
```

For the view angle, pick one:
- `perfectly flat front view` — for things that face you (faces, helmets, badges)
- `perfectly flat side view` — for things with a clear profile (fish, cars, tools)
- `slight 3/4 view` — for things that would look flat or boring from the side (buckets, backpacks, bowls)

**Real examples from Carter's Games:**

> `Isolated on white background, cute brown bear sitting upright, friendly expression, simple shapes, perfectly flat front view, thick black outlines, vibrant colors, children's cartoon image.`

> `Isolated on white background, single trout fish, blue and silver with pink stripe, facing right, perfectly flat side view, thick black outlines, vibrant colors, children's cartoon image.`

> `Isolated on white background, small orange camping tent, triangular, front flap open, slight 3/4 view, thick black outlines, vibrant colors, children's cartoon image. No text, no words, no labels.`

**Tips:**
- Add `no text, no words, no labels` when the item might have writing on it (books, bottles, signs).
- Keep descriptions short — one item, one color, one detail.
- Generate a few versions and pick your favorite.

### Generating background scenes

Use the same Gemini app for full backgrounds. Describe what the scene should look like:

```
Children's book illustration of a large, busy [THEME] scene packed with things to find.
[2-3 sentences describing the environment].
Wide and panoramic, landscape orientation.
Bright saturated colors, flat design, thick black outlines, no text.
Every part of the scene is filled with interesting details — [list 4-5 background fillers].
```

**Real example from Carter's Games (mountain scene):**

> *Children's book illustration of a large, busy mountain scene packed with things to find. Snow-capped peaks in the background, pine forest on the slopes, a winding trail, a mountain lake, rocky cliffs, meadows with wildflowers. Wide and panoramic, landscape orientation. Bright saturated colors, flat design, thick black outlines, no text. Every part of the scene is filled with interesting details — rocks, bushes, snowdrifts, fallen logs, streams.*

### Remove white backgrounds — let AI do it

Item images come back with a white background. To make it transparent for use in the game, just ask your AI coding tool:

> *"I have a folder of PNG images in assets/sprites/. Can you remove the white background from each one and save them as transparent PNGs?"*

Claude Code or Gemini CLI will handle it. No separate tool needed.

### Get images into Godot — let AI do it too

> *"I've added new images to assets/sprites/. Can you import them into the Godot project and make sure they're ready to use?"*

AI will move the files into the right place and set up the Godot import settings.

---

## Chapter 7: Test It

Before you share your game with anyone, play it yourself — and find someone else to watch.

### The "watch someone else play" trick

Sit next to a friend or sibling and watch them play your game **without telling them anything.** Don't explain the rules. Don't say "no, tap *that* button." Just watch.

Where they get confused, that's something you need to fix. Where they smile or laugh, that's something you should keep.

### Things to test

- Does it work on a tablet or phone? (If you built it for touch, test it on touch)
- Does it break if you tap in unexpected places?
- Is it too easy? Too hard?
- Does the game ever get stuck in a state where nothing happens?

### Local testing in a browser

To test your game on your own computer, click the **Play** button (the triangle icon) in the top-right corner of Godot. 

If you want to test how your game will run in a web browser before publishing it, Godot has a built-in one-click feature!

#### Option 1: Ask your AI helper (Easiest)
The exact steps vary slightly by Godot version, so the fastest path is to ask:

> *"How do I run my Godot 4 game in a browser locally for testing, without doing a full export?"*

Godot 4.3 and later have a built-in "Run in Browser" button — your AI helper can point you to it for your exact version.

#### Option 2: The Command Line Way (Advanced)
If you want to build and host it from your terminal, run these commands:

```bash
# In your project folder, export the game
godot --headless --export-release "Web" local/exports/html/index.html

# Then serve it locally
cd local/exports/html && python -m http.server 8080
# Open http://localhost:8080 in your browser
```

> [!TIP]
> **If you get a 'godot not found' or 'command not found' error:** Your computer doesn't know where Godot is installed. Ask your AI helper: *"I got a 'command not found' error when trying to run the godot command in terminal. How do I run it using the full path to where my Godot app is located on [Windows/Mac]?"*

---

## Chapter 8: Share It with the World

This is where your game goes from living on your computer to being something you can send a link to anyone.

### Before You Export: Install Export Templates

Godot needs **Export Templates** before it can package your game for the web. You only need to do this once.

1. In Godot, open **Project → Export**
2. If you see a red warning saying templates are missing, click **Manage Export Templates** and then **Download and Install**
3. Wait for the download to finish, then close that window — you're ready to export

### Option A: itch.io (easiest, no code required)

[itch.io](https://itch.io) is a game hosting site used by indie developers worldwide. Free to use.

1. Create an account at [itch.io](https://itch.io)
2. In Godot, open **Project → Export**, add a "Web" preset, and export to a folder on your computer
3. Zip up that export folder
4. On itch.io, click **Upload new project**, upload the zip, and set it to "HTML" type and "Public" visibility
5. Done — you have a link you can share

---

### Option B: GitHub Pages (free)

GitHub Pages lets you host your game directly from your GitHub repository. 

#### The Simple Way (No code required)
1. In Godot, export your game locally to a folder in your project named `docs` (specifically set the export file path to `docs/index.html`).
2. Commit and push your changes to GitHub.
3. On your GitHub repository page, click **Settings** -> **Pages**.
4. Under **Build and deployment**, set the Source to **Deploy from a branch**.
5. Select your `main` branch and change the folder option from `/ (root)` to `/docs`. Click **Save**.
6. Your game will be live at `yourusername.github.io/your-repo-name`!

#### The Automated Way (GitHub Actions)
For advanced users, you can have AI write a GitHub Actions workflow to export your game in the cloud and deploy it automatically. 

> [!IMPORTANT]
> **Two things you MUST do to make GitHub Actions work:**
> 1. **Enable Write Permissions:** Go to your repository's **Settings -> Actions -> General**. Scroll down to **Workflow permissions** and choose **Read and write permissions**, then click **Save**. If you don't do this, GitHub will block your deployment!
> 2. **Fix the Black Screen (SharedArrayBuffer):** Godot 4 web exports require a browser feature called `SharedArrayBuffer` to run. While itch.io handles this with a single setting checkbox, GitHub Pages does not support it out-of-the-box, causing a **black screen**. To fix it, you need to add a small script called `coi-serviceworker.js` to your exported web folder. 
> Ask your AI helper: *"How do I use coi-serviceworker.js to fix the Godot 4 black screen on GitHub Pages?"*

Carter's Games uses GitHub Actions for this. The workflow:
1. Exports the game using Godot running in the cloud (no Godot needed on your computer)
2. Uploads the files to GitHub Pages automatically
3. Makes the game available at `yourusername.github.io/your-repo-name`

This takes some setup, but once it's working, deploying is just clicking a button.

### Option C: Both (what Carter's Games does)

Carter's Games deploys to both itch.io and GitHub Pages from a single automated build. The GitHub Actions workflow runs Godot in the cloud, packages the game, and pushes to both places at once. This is a more advanced setup, but a great learning project for working with AI to build automation.

> **Ask your AI helper:** *"I want to deploy my Godot web export to both itch.io (using a tool called 'butler') and GitHub Pages from the same GitHub Actions workflow. Can you write the workflow YAML file?"*

### Costs at this stage

- GitHub Pages: **Free**
- itch.io: **Free** (they take a cut of sales if you charge money, but free games cost nothing)

---

## Chapter 9: Keep Going

Shipping your first version is just the beginning. Here's how to keep building without losing your work.

### Use Git Branches — and Let AI Handle Git

Git is the tool that tracks every change to your game. It lets you go back in time if something breaks, and keeps your finished working game safe while you experiment with new features.

The key habit is: **never build directly on your main game.** Instead, create a **branch** for each new feature — a separate copy of your project where you can safely experiment. If something goes wrong, you haven't touched your main game.

You don't need to learn git commands. Claude Code handles all of it. Here are the prompts to use:

| What you want | What to say |
|---------------|-------------|
| Start working on a new feature | *"Create a new branch called feat/add-sound-effects"* |
| Save your progress | *"Commit all my changes with a good message describing what we built"* |
| Share it on GitHub | *"Push this branch to GitHub and open a pull request"* |
| Finalize a finished feature | *"The PR looks good — merge it into main"* |

> **Why branches matter:** Imagine you've just finished Phase 2 and it's working perfectly. You start building Phase 3 and something breaks badly. With branches, you can throw away Phase 3's changes and your Phase 2 game is completely untouched. Without branches, you might lose everything you had working.

### Adding new content

One of the best things about planning your game well from the start is that **adding content later requires no new code.** In Carter's Games, adding a new hidden-objects scene is just:
1. Generate the art
2. Import it into Godot
3. Use the in-game Scene Builder tool to place item locations and hitboxes
4. Save it directly as a Godot resource file (`.tres`)

The game code automatically detects your new resource and loads it. No programming required!

### Get feedback and keep improving

- Share your link with friends and watch them play
- Ask: *"What was confusing?"* and *"What was your favorite part?"*
- Make one thing better each week

---

## Chapter 10: When You Get Stuck

Getting stuck is not a sign that you're bad at this. Every developer gets stuck — the key is knowing how to get unstuck.

### First: describe the problem out loud

Before you ask anyone (AI or human), try explaining the problem out loud to yourself — or to a pet, a stuffed animal, whatever. This sounds silly but it works. The act of forming a sentence like *"I expected the fish to swim left when it hits the wall, but instead it freezes"* often reveals what's wrong before you even ask.

### How to ask the AI when you're stuck

The single most common mistake is asking something like:

> *"It doesn't work."*

The AI has no idea what "it" is, what "doesn't work" means, or what you expected to happen. Here's the formula that actually gets results:

```
I'm building [describe your game] in Godot 4.

Here's what I'm trying to do: [what you want to happen]

Here's what's actually happening: [what's going wrong]

Here's the error message (if there is one): [paste it exactly]

What's wrong?
```

**Real example:**

> *"I'm building a fishing game in Godot 4. I have a fish node that's supposed to reverse direction when it hits the edge of the screen. What's actually happening is the fish swims off the left edge and disappears. There's no error message. What's wrong?"*

That's the kind of prompt that gets a useful answer.

### When something doesn't work the first time

This happens constantly. It's not a failure — it's just how the process goes. When something AI built doesn't work:

1. **Describe what happened vs. what you expected.** *"The fish moves off-screen instead of bouncing back."*
2. **If there's an error message in Godot**, tell AI what it says — Claude Code can often see the error directly, or you can read it to AI.
3. **Stay in the same conversation.** AI already knows what it built. Just keep talking.

Don't throw the whole thing away and start over after one failure. Usually you're one or two exchanges away from it working.

### When you've been going in circles for a while

If you've been stuck on the same thing for 20+ minutes and nothing is working, try this:

**1. Ask AI to start fresh with a simpler version:**
> *"Let's set aside what we have and build the simplest possible version of [the thing that's broken] — just enough to prove it works. Then we can add the rest back."*

Get the tiny version working first, then rebuild from there.

**2. Give AI more context:**
> *"Here's my full game plan: [paste plan]. We're on Phase [N]. Here's what's happening: [describe the problem]. Here's what I expected: [describe what you wanted]. Can you figure out what's wrong?"*

The more context AI has, the better it can diagnose the problem.

**3. Ask AI to check the simple stuff:**
> *"What are the most common reasons something like this would stop working in Godot 4? Can you check if any of those apply to what we built?"*

**4. Take a break.**
Seriously. Walk away for 10 minutes. Come back. You'll often see the problem immediately — or be able to describe it more clearly to AI.

### When you don't understand what AI did

You don't need to read or understand the code — but you should understand *what* was built and *why*, so you can keep directing it. If something is unclear, ask:

> *"Can you explain what you just built in plain English? What does each part do?"*

You should be able to say something like *"the fish bounces because there's a script watching for when it hits the edge, then it flips direction."* You don't need to know how the code does it — just what it does. That's enough to keep building.

### When to ask a human

AI is great at fixing specific, concrete bugs. It's less good at:

- Helping you decide **if your game idea is fun** (ask a real person to play it)
- Noticing when your game **feels slow or frustrating** (watch someone play it)
- Telling you **what to build next** when you have 10 options (that's a judgment call)

For those things, a friend, a sibling, or the adult helping you will be more useful than any AI.

### Keeping track of what you've tried

When you're deep in a bug, it's easy to forget what you already tried. Keep a simple scratch note (a text file, a sticky note) while you're debugging:

```
Problem: fish swims off screen
Tried: checked position, tried clamping, tried Area2D
Still broken: yes as of 3pm
```

This saves you from going in circles and makes it easier to explain the problem to someone else.

---

## Quick Reference: All Your Tools

| What you need | Tool | Link |
|---------------|------|------|
| Build and run the game | Godot 4 | [godotengine.org](https://godotengine.org) |
| AI that builds directly on your computer | Claude Code | [claude.ai/code](https://claude.ai/code) |
| AI that builds directly on your computer (Google) | Gemini CLI | install via `npm install -g @google/gemini-cli` |
| Visual AI code editor | Cursor | [cursor.com](https://cursor.com) |
| Terminal app (Mac) | iTerm2 | [iterm2.com](https://iterm2.com) |
| AI planning, chat, and image generation | Gemini (web or phone) | [gemini.google.com](https://gemini.google.com) |
| AI planning and chat | Claude (web) | [claude.ai](https://claude.ai) |
| Store and version your code | GitHub | [github.com](https://github.com) |
| Publish your game | itch.io | [itch.io](https://itch.io) |
| Host your game on the web (free) | GitHub Pages | [pages.github.com](https://pages.github.com) |

### Helpful AI prompts to keep handy

| When you need... | Ask the AI... |
|-----------------|---------------|
| To start your game plan | *"Here's my game idea: [brain dump everything]. I'm building it in Godot 4. Before writing any code, can you ask me clarifying questions and then write a complete game design document with a phase breakdown?"* |
| To start a new phase | *"Here's my full game plan: [paste plan]. Phase [N] is done. Now I want to build Phase [N+1]: [describe it]."* |
| To understand a Godot concept | *"In Godot 4, what is [confusing thing]? Explain it simply with a short example."* |
| To fix a bug | *"Here's my game plan for context: [paste plan]. This is happening: [describe it]. I expected: [what you wanted]. Can you find and fix it?"* |
| To generate game art | Ask Gemini: *"Generate a children's cartoon image: isolated on white background, [item], [view angle], thick black outlines, vibrant colors."* |
| To remove image backgrounds | *"Remove the white background from all PNGs in assets/sprites/ and save them as transparent PNGs."* |
| To set up GitHub Actions | *"Write a GitHub Actions workflow that exports my Godot 4 game and deploys it to GitHub Pages."* |

---

## Final Note

The most important thing isn't any tool or technique in this guide — it's finishing something. A simple game that works and is published is worth more than a complex game that never gets finished.

Carter's Games started as *"what if you could tap fish?"* — and grew from there over weeks of work, one feature at a time, with a lot of AI help along the way.

You can do the same thing. Start simple, finish it, ship it, and then make it better.

Good luck. 🎮
