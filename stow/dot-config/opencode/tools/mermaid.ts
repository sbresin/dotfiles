import { tool } from "@opencode-ai/plugin";
import { mkdir } from "fs/promises";
import path from "path";

type Format = "svg" | "png";
type Theme = "default" | "dark" | "forest" | "neutral";

async function hasCommand(cmd: string): Promise<boolean> {
	try {
		await Bun.$`which ${cmd}`.quiet();
		return true;
	} catch {
		return false;
	}
}

async function ensureScratchDir(sessionID: string): Promise<string> {
	const dir = path.join("/tmp", `opencode-${sessionID}`);
	await mkdir(dir, { recursive: true });
	return dir;
}

export default tool({
	description:
		"Render a Mermaid diagram to SVG or PNG. " +
		"Returns the file path and base64-encoded data. " +
		"SVG is the default format and works well with Confluence. " +
		"Use this when you need to create diagrams for documentation.",
	args: {
		code: tool.schema.string().describe("Mermaid diagram code (e.g., 'graph TD; A-->B;')"),
		format: tool.schema
			.enum(["svg", "png"])
			.optional()
			.describe("Output format: 'svg' (default) or 'png'"),
		theme: tool.schema
			.enum(["default", "dark", "forest", "neutral"])
			.optional()
			.describe("Diagram theme: 'default', 'dark', 'forest', or 'neutral'"),
		backgroundColor: tool.schema
			.string()
			.optional()
			.describe("Background color (CSS color string). Defaults to 'transparent'"),
		scale: tool.schema
			.number()
			.optional()
			.describe("Scale factor for PNG output (default: 2 for retina). Ignored for SVG."),
		outputPath: tool.schema
			.string()
			.optional()
			.describe("Explicit output file path. If omitted, uses the session scratch directory."),
	},
	async execute(args, context) {
		if (!(await hasCommand("mmdc"))) {
			throw new Error(
				"mermaid-cli (mmdc) is not installed. " +
					"Add 'mermaid-cli' to your nix packages or install via npm: npm install -g @mermaid-js/mermaid-cli"
			);
		}

		const format: Format = args.format ?? "svg";
		const theme: Theme = args.theme ?? "default";
		const backgroundColor = args.backgroundColor ?? "transparent";
		const scale = args.scale ?? 2;

		const scratchDir = await ensureScratchDir(context.sessionID);
		const timestamp = Date.now();
		const inputFile = path.join(scratchDir, `mermaid-${timestamp}.mmd`);
		const outputFile =
			args.outputPath ?? path.join(scratchDir, `diagram-${timestamp}.${format}`);

		// Write mermaid code to temp file
		await Bun.write(inputFile, args.code);

		// Build mmdc command arguments
		const mmdcArgs = [
			"mmdc",
			"-i",
			inputFile,
			"-o",
			outputFile,
			"-t",
			theme,
			"-b",
			backgroundColor,
		];

		// Add scale for PNG only
		if (format === "png") {
			mmdcArgs.push("-s", scale.toString());
		}

		// Run mermaid-cli
		try {
			const result = await Bun.$`${mmdcArgs}`.quiet();
			if (result.exitCode !== 0) {
				const stderr = result.stderr.toString();
				throw new Error(`mermaid-cli failed: ${stderr}`);
			}
		} catch (e: any) {
			// Clean up input file on error
			try {
				await Bun.$`rm -f ${inputFile}`.quiet();
			} catch {}
			throw new Error(`Failed to render diagram: ${e.message}`);
		}

		// Read the output file and encode as base64
		const outputData = await Bun.file(outputFile).arrayBuffer();
		const base64Data = Buffer.from(outputData).toString("base64");

		// Clean up input file
		try {
			await Bun.$`rm -f ${inputFile}`.quiet();
		} catch {}

		const mimeType = format === "svg" ? "image/svg+xml" : "image/png";

		return [
			`Rendered ${format.toUpperCase()} diagram to: ${outputFile}`,
			``,
			`Format: ${format}`,
			`MIME type: ${mimeType}`,
			`Theme: ${theme}`,
			`Background: ${backgroundColor}`,
			``,
			`Data URI (for embedding):`,
			`data:${mimeType};base64,${base64Data}`,
		].join("\n");
	},
});
