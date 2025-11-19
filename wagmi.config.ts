import { defineConfig } from "@wagmi/cli";
import { foundry, react } from "@wagmi/cli/plugins";

export default defineConfig({
	out: "wagmi.generated.ts",
	plugins: [
		foundry({
			project: "./",
			exclude: ["MockERC20.sol", "Sale.d.sol", "IERC20.sol", "Deploy.s.sol"],
			// legacy name, for compatibility reasons
			namePrefix: "Ctznd",
			deployments: {
				Sale: {
					31337: "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0",
					421614: "0x5e4bf20bbb995bd6a30d1e384c85a56b5ad703e4",
				},
			},
		}),
		react(),
	],
});
