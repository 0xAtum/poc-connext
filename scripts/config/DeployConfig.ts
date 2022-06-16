import { SupportedChain } from "./NetworkConfig"

export interface IDeployConfig {
	TX_CONFIRMATIONS: number
	ContractConfigs: CrossChainConfig
}

export type CrossChainConfig = {
	[key in SupportedChain | string]?: ContractConfig
}

export interface ContractConfig {
	connext: string
	domain: number
}
