# SWE-Bench Evaluation with Qwen3-Coder-Next on DGX Spark

## Project Overview

This project aims to replicate and evaluate the Qwen3-Coder-Next-FP8 model on SWE-Bench Multilingual using a single DGX Spark system. The work consists of four phases: setting up the model infrastructure, then evaluating it with three different test harnesses (default SWE-Bench, SWE-Agent, and optionally mini-SWE-agent).

## Current State

**Phase 1 Complete:**
- Docker configured and operational
- vLLM server running: Qwen3-Coder-Next-FP8 on port 8888 (vLLM 0.15.2rc1, 262K max context)
- Model weights downloaded to `~/.cache/huggingface/hub/`
- Scripts: `launch-vllm.sh` (with daemon mode), `validate-vllm.sh`
- Validation results in `results/phase1/`

**Phase 2 Skipped:**
- SWE-bench default harness incompatible with custom vLLM endpoint

**Phase 3 In Progress:**
- ✅ ARM64 container images: 295/300 built successfully (78% of 377 attempts)
- ✅ SWE-bench patched for ARM64 support (fork: github.com/SailorJoe6/SWE-bench, branch: arm64-support)
- ✅ SWE-agent patched for ARM64 support (fork: github.com/SailorJoe6/SWE-agent, branch: arm64-support)
- ✅ Configuration: `config/qwen3-vllm.yaml` with ARM64 defaults
- ⏳ **Evaluation Running**: 295 instances started in background (nohup), output: `results/full-arm64-eval/`
- ⚠️ 82 instances failed to build (documented in execution plan)

**Documentation Complete:**
- `docs/arm64-support/README.md` - Full implementation guide
- `docs/arm64-support/QUICKSTART.md` - Quick reference
- `docs/arm64-support/CHANGES.md` - Detailed code changes
- `scripts/tag-arm64-images.sh` - Image tagging automation

**Known Issues:**
- vLLM 0.15.x has argparse conflict bug in `vllm serve` CLI; use `python3 -m vllm.entrypoints.openai.api_server` instead
- 82 container builds failed on ARM64 (mostly Rust, Ruby, JavaScript projects) - troubleshooting planned as Step 3.6

## Target State

Upon completion, the project will have:
- Qwen3-Coder-Next-FP8 running on vLLM infrastructure using the custom Spark container
- Complete evaluation results from SWE-Bench Multilingual across multiple harness configurations
- Formatted reports (summary and detailed) for each evaluation run
- Preserved prediction files for detailed analysis
- Structured results directory for all outputs

## Environment

- **Hardware**: Single DGX Spark system (NVIDIA Grace, ARM64/aarch64)
- **Container Runtime**: Docker (configured)
- **Base Images**:
  - ARM64 native: 22 base images + 295 instance images built
  - Using patched SWE-bench fork for ARM64 support
  - 82 instances failed to build (see execution plan for details)
- **Network**: No restrictions for HuggingFace or GitHub access
- **Architecture Note**: ARM64 native execution; results not comparable to x86_64 benchmarks
- **Repositories**: Using ARM64-patched forks:
  - SWE-bench: github.com/SailorJoe6/SWE-bench (branch: arm64-support)
  - SWE-agent: github.com/SailorJoe6/SWE-agent (branch: arm64-support)

## Phase 1: Qwen3-Coder-Next-FP8 vLLM Setup

### Objective
Deploy Qwen3-Coder-Next-FP8 model on vLLM using the custom Spark container and validate that the API server is operational.

### Implementation Details

**Container Setup**:
- Use the custom vLLM container from https://github.com/eugr/spark-vllm-docker/
- Run the provided script with `--solo` flag (single Spark configuration)
- Follow instructions from https://forums.developer.nvidia.com/t/how-to-run-qwen3-coder-next-on-spark/359571

**Model Acquisition**:
- Download Qwen3-Coder-Next-FP8 weights from https://huggingface.co/Qwen/Qwen3-Coder-Next-FP8
- Expected download time: multiple hours
- Download process is resumable by default (HuggingFace tools)

**Model Configuration**:
- Primary source: Configuration specified in the NVIDIA forum blog post
- Fallback source: Optimal settings from the Qwen3-Coder-Next-FP8 HuggingFace repository
- Apply these configurations for temperature, top_p, max tokens, and other sampling parameters

**Success Criteria**:
- vLLM server successfully responds to API requests
- Model loads without errors
- API endpoints are accessible and functional

**Status**: ✅ COMPLETE

**Outputs**:
- Scripts: `scripts/launch-vllm.sh`, `scripts/validate-vllm.sh`
- Validation results in `results/phase1/` (health.json, models.json, test-completion.json, validation-summary.txt)
- Server running on port 8888 (container: `vllm_node`)

## Phase 2: SWE-Bench Default Harness Evaluation

### Status: **SKIPPED**

**Reason**: The default SWE-bench harness (`run_api.py`) has hardcoded model names and uses `tiktoken.encoding_for_model()` which only works with official OpenAI/Anthropic models. It cannot be adapted to work with the custom vLLM endpoint without significant modifications.

**Decision**: Skip to Phase 3 (SWE-Agent) which is designed to work with custom models and provides the primary evaluation target for this project.

## Phase 3: SWE-Agent Harness Evaluation

### Status: **IN PROGRESS** ⏳

**Current State**:
- One successful test run (apache__druid-13704) to validate setup
- 295 instances ready (all successfully built and tagged ARM64 images)
- Next run output: `results/phase3/full-run/`
- Expected duration: 49-98 hours (10-20 min per instance)

### Objective
Evaluate Qwen3-Coder-Next-FP8 on SWE-Bench Multilingual using the SWE-Agent framework with native ARM64 containers.

### Implementation Details

**Test Suite**:
- SWE-Bench Multilingual test slice (295 instances with working ARM64 images)
- Using ARM64-patched SWE-Agent fork (github.com/SailorJoe6/SWE-agent, branch: arm64-support)
- Excluding 82 instances that failed to build as ARM64 containers

**Model Configuration**:
- Connect to the vLLM server from Phase 1 (localhost:8888)
- Configuration: `config/qwen3-vllm.yaml`
- Parameters: temperature=1.0, top_p=0.95, max_tokens as needed

**ARM64 Implementation**:
- Native ARM64 Docker images (no QEMU emulation)
- Chrome → Chromium substitution for JavaScript projects
- Architecture-specific pnpm downloads for Node.js projects
- Complete documentation: `docs/arm64-support/README.md`

**Execution Strategy**:
- Sequential processing (single concurrent request constraint)
- SWE-agent has built-in resume logic for interruptions
- Running in background with nohup
- Trajectories saved per instance

**Outputs**:
- Formatted report with summary metrics (pass rates, resolved instances)
- Formatted report with detailed per-instance results
- All JSON prediction files preserved in `results/phase3/full-run/preds.json`
- Individual trajectories in `results/phase3/full-run/<instance-id>/`
- All evaluation logs stored in `results/phase3/full-run/`

### Next Steps After Completion

1. **Step 3.4**: Evaluate predictions using SWE-bench harness
2. **Step 3.5**: Generate formatted reports
3. **Step 3.6**: Troubleshoot and fix 82 failed container builds (optional)

## Phase 4: mini-SWE-agent Harness Evaluation (Optional)

### Objective
Evaluate Qwen3-Coder-Next-FP8 on the complete SWE-Bench Multilingual test slice using the mini-SWE-agent framework for comparison with Phase 2 and Phase 3 results.

### Implementation Details

**Test Suite**:
- Run SWE-Bench Multilingual test slice (all languages)
- Use mini-SWE-agent framework from https://github.com/SWE-agent/mini-SWE-agent

**Model Configuration**:
- Connect to the vLLM server from Phase 1
- Use same configuration parameters as Phase 1

**Execution Strategy**:
- Check for any built-in skip logic to avoid re-running completed test instances
- If not built-in, implement simple deduplication to skip already-completed instances
- Long-running process expected (potentially many hours)

**Outputs**:
- Formatted report with summary metrics for comparison with Phase 2 and Phase 3
- Formatted report with detailed per-instance results
- All evaluation logs stored in `results/phase4/`

**Activation**:
- This phase is conditional on successful completion of Phase 3
- Decision to proceed will be made after reviewing Phase 3 results

## Results Directory Structure

```
results/
├── phase1/                    # vLLM validation outputs and logs
├── phase2/                    # SWE-Bench default harness results (skipped)
├── phase3/                    # SWE-Agent harness results and JSON predictions
│   ├── full-arm64-eval/       # Initial test run (apache__druid-13704 only)
│   └── full-run/              # Complete 295-instance evaluation (pending)
└── phase4/                    # mini-SWE-agent harness results (optional)
```

## Key References

- **Primary Setup Guide**: https://forums.developer.nvidia.com/t/how-to-run-qwen3-coder-next-on-spark/359571
- **Custom vLLM Container**: https://github.com/eugr/spark-vllm-docker/
- **Model Weights**: https://huggingface.co/Qwen/Qwen3-Coder-Next-FP8
- **SWE-Bench Framework**: https://github.com/SWE-bench/SWE-bench
- **SWE-Agent Framework**: https://github.com/SWE-agent/SWE-agent
- **mini-SWE-agent Framework**: https://github.com/SWE-agent/mini-SWE-agent

## Success Criteria Summary

**Phase 1**: vLLM API server operational and responding to requests

**Phase 2**: Complete evaluation results with formatted reports for SWE-Bench default harness

**Phase 3**: Complete evaluation results with formatted reports and JSON predictions for SWE-Agent harness

**Phase 4**: Complete evaluation results with formatted reports for mini-SWE-agent harness (if activated)

## Notes

- All evaluation phases depend on successful completion of Phase 1
- Phase 4 is optional and will be activated based on Phase 3 success
- Long-running processes (model download, evaluations) are expected and should be planned for accordingly
- Resumability for interrupted evaluations should leverage framework built-ins where available
