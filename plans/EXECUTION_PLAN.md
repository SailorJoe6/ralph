# Execution Plan: SWE-Bench Evaluation with Qwen3-Coder-Next on DGX Spark

## 🎯 PROJECT UNBLOCKED - Option C Selected

**Decision**: Skip Phase 2 (default harness) and proceed directly to Phase 3 (SWE-Agent).

**Rationale**:
- SWE-bench `run_api.py` has hardcoded model names incompatible with custom vLLM endpoints
- SWE-Agent framework is designed for custom models and provides better tooling support
- Phase 3 (SWE-Agent) is the primary target for evaluation - default harness was for baseline comparison only
- This path gets to meaningful results faster

## Progress

| Step | Description | Status |
|------|-------------|--------|
| 0.1 | Create results directory structure | **DONE** |
| 0.2 | Create docs/README.md | **DONE** |
| 1.1 | Clone spark-vllm-docker and build container | **DONE** (vllm-node:latest, 22.1GB) |
| 1.2 | Download Qwen3-Coder-Next-FP8 model weights | **DONE** (51 files at ~/.cache/huggingface/hub/) |
| 1.3 | Launch vLLM server | **DONE** (python3 -m vllm.entrypoints.openai.api_server; workaround for vLLM 0.15.x argparse bug) |
| 1.4 | Validate API server | **DONE** (3/3 checks pass: health, models, chat completion) |
| 1.5 | Create launch script and record results | **DONE** (scripts/launch-vllm.sh updated with daemon mode + --logs; validate-vllm.sh bugfix) |
| 2.1 | Install SWE-bench | **DONE** (installed in venv at ~/Code/swebench-eval-next/venv) |
| 2.2 | Generate predictions (default harness) | **SKIPPED** (incompatible with custom vLLM) |
| 2.3 | Run evaluation harness | **SKIPPED** |
| 2.4 | Generate reports | **SKIPPED** |
| 3.0 | Rebuild SWE-bench images as ARM64 | **DONE** (299/300 ARM64 images built; 1 unfixable) |
| 3.1 | Install SWE-agent | **DONE** (SWE-agent 1.1.0 with ARM64 patches in venv) |
| 3.2 | Configure SWE-agent for local vLLM | **DONE** (config/qwen3-vllm.yaml with ARM64 defaults) |
| 3.3 | Tag ARM64 images for SWE-agent | **DONE** (all 295 images tagged) |
| 3.4 | Run SWE-agent against SWE-bench Multilingual | **IN PROGRESS** (9/299 instances, 8 submitted, 1 exit_error) |
| 3.5 | Evaluate predictions | TODO |
| 3.6 | Generate reports and preserve artifacts | TODO |
| 3.7 | Troubleshoot and fix failed ARM64 container builds | **DONE** (5 fixed, 1 unfixable) |
| 4.1 | Install mini-SWE-agent | TODO (optional) |
| 4.2 | Configure for local vLLM | TODO (optional) |
| 4.3 | Run against SWE-bench Multilingual | TODO (optional) |
| 4.4 | Evaluate and report | TODO (optional) |

## Environment Snapshot

- **Hardware**: DGX Spark (NVIDIA Grace ARM64), 119GB RAM, 20 CPUs
- **Architecture**: aarch64 (ARM64) - using native ARM64 Docker images
- **Docker**: Operational
- **SWE-bench images**:
  - **ARM64 native**: 295/300 instance images built successfully (98.3% of buildable)
  - **Base images**: 22 language/version base images (all required variants)
  - **Failed builds**: 82 instances failed to build (see Failed Container Builds section below)
  - **Repository forks**: Using ARM64-patched forks at github.com/SailorJoe6/SWE-bench and SWE-agent
- **spark-vllm-docker**: Cloned at `~/Code/spark-vllm-docker/`; `vllm-node:latest` image built (22.1GB)
- **Model weights**: Downloaded (Qwen/Qwen3-Coder-Next-FP8 at `~/.cache/huggingface/hub/`)
- **vLLM server**: Validated and operational (vLLM 0.15.2rc1, port 8888, 262K max context, ~199K KV cache tokens)
- **Python environment**: Virtual environment at `~/Code/swebench-eval-next/venv` (Python 3.12)
- **Tooling**: SWE-bench 4.1.0 (ARM64 fork), SWE-agent 1.1.0 (ARM64 fork) installed in venv
- **SWE-Agent config**: `config/qwen3-vllm.yaml` configured with ARM64 defaults, function_calling, litellm_model_registry
- **Evaluation status**: Full 295-instance evaluation running in background (nohup)

## Constraints

- **Single concurrent model request**: The DGX Spark cannot handle parallel requests to the model. vLLM must be configured with `--max-num-seqs 1` to enforce single-request processing.
- **Limited agent parallelism**: In Phase 3 (SWE-Agent), at most 2-3 agent instances can run in parallel. Agents spend time on code search (not model inference), allowing the request queue to clear between inference calls. More than 3 agents leads to excessive queueing.
- **ARM64 architecture**: System is NVIDIA Grace (aarch64). SWE-bench images must be built as native ARM64 to avoid QEMU emulation issues that cause Rust/Go compilation failures.
- **Image compatibility**: Results not comparable to published x86_64 benchmarks due to architecture difference, but valid for comparing models on same platform.

## Failed Container Builds

**Status**: 82 out of 377 attempted instance builds failed (78% success rate, 295 working images)

**Affected Projects** (by failure count):
- Ruby: rubocop (8 instances)
- JavaScript: preactjs (8 instances)
- Rust: tokio-rs (7), sharkdp (6 instances)
- PHP: phpoffice (7), php-cs-fixer (1 instances)
- Go: fluent (5 instances), caddyserver (3), gohugoio (1)
- C: burntsushi (1 instance)
- Other: Various projects (1-3 failures each)

**Root Causes** (preliminary):
1. **Missing ARM64 packages**: Some apt/npm/cargo packages unavailable for ARM64 architecture
2. **Hardcoded x86_64 dependencies**: Build scripts with architecture-specific assumptions
3. **Compilation issues**: ARM64-specific compiler errors or missing platform support

**Impact**:
- **Evaluation running** with 299/300 instances (7 completed as of 2026-02-11)
- Only 1 instance excluded: `tokio-rs__tokio-4384` (upstream Cargo.lock issue)
- Full coverage across all major languages maintained

**Current Status** (Step 3.4 in progress):
- Output: `results/phase3/full-run/`
- Progress: 9/299 instances (8 submitted, 1 exit_error)
- Last completed: `apache__lucene-12196` (2026-02-11 00:40)
- Currently processing: `apache__lucene-12212` (started 2026-02-11 00:40)
- Estimated completion: ~49-98 hours from start (2026-02-10 21:10)

---

## Step 0: Project Scaffolding

### Step 0.1: Create Results Directory Structure

```bash
mkdir -p results/{phase1,phase2,phase3,phase4}
```

### Step 0.2: Create Documentation Directory

```bash
mkdir -p docs
```

Create `docs/README.md` as an index for all scripts and tools developed during this project. Update this document whenever new scripts or tools are created in subsequent phases.

**Deliverables**: `docs/README.md` with initial index structure

---

## Phase 1: Qwen3-Coder-Next-FP8 vLLM Setup

### Step 1.1: Clone spark-vllm-docker and Build Container

```bash
cd ~/Code
git clone https://github.com/eugr/spark-vllm-docker.git
cd spark-vllm-docker
./build-and-copy.sh --use-wheels
```

**Notes**:
- This builds a `vllm-node` image optimized for DGX Spark with the correct vLLM version
- The pre-pulled `nvcr.io/nvidia/vllm` images do NOT have the right vLLM version — do not use them
- Build may take significant time (compiling from wheels)
- Verify the build succeeds with `docker images | grep vllm-node`

**Success**: `vllm-node` image present in `docker images`

### Step 1.2: Download Qwen3-Coder-Next-FP8 Model Weights

Can run in parallel with Step 1.1.

```bash
# Install huggingface-cli if not present
pip install huggingface_hub[cli]

# Download model (resumable)
huggingface-cli download Qwen/Qwen3-Coder-Next-FP8
```

**Notes**:
- Model is 80B params (FP8), expect ~80-90GB download
- Download is resumable by default
- Weights cache to `~/.cache/huggingface/hub/`
- Expected download time: multiple hours depending on bandwidth

**Success**: Model directory present at `~/.cache/huggingface/hub/models--Qwen--Qwen3-Coder-Next-FP8/`

### Step 1.3: Launch vLLM Server

```bash
cd ~/Code/spark-vllm-docker
./launch-cluster.sh --solo \
  exec vllm serve Qwen/Qwen3-Coder-Next-FP8 \
    --enable-auto-tool-choice \
    --tool-call-parser qwen3_coder \
    --gpu-memory-utilization 0.8 \
    --host 0.0.0.0 --port 8888 \
    --load-format fastsafetensors \
    --attention-backend flashinfer \
    --enable-prefix-caching \
    --max-num-seqs 1
```

**Notes**:
- Command follows the NVIDIA forum blog post exactly, plus `--max-num-seqs 1`
- `--max-num-seqs 1` enforces single concurrent request processing (DGX Spark hardware constraint)
- Port 8888 per the NVIDIA forum reference
- `--gpu-memory-utilization 0.8` allocates ~92GB VRAM
- `--attention-backend flashinfer` enables ~170K context (vs 60K with FLASH_ATTN)
- `--enable-prefix-caching` critical for coding workflow performance
- If server fails to start (OOM), try adding `--max-model-len 32768`

**Success**: Server responds to health check

### Step 1.4: Validate API Server

```bash
# Health check
curl http://localhost:8888/health

# Model list
curl http://localhost:8888/v1/models

# Test completion
curl http://localhost:8888/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen3-Coder-Next-FP8",
    "messages": [{"role": "user", "content": "Write a Python hello world"}],
    "temperature": 1.0,
    "top_p": 0.95,
    "top_k": 40
  }'
```

**Success**: All three endpoints return valid responses

### Step 1.5: Create Server Launch Script and Record Results

Create a reusable script (e.g., `scripts/launch-vllm.sh`) that encapsulates the launch command from Step 1.3. Document it in `docs/README.md`.

Save validation logs, server config, and test outputs to `results/phase1/`.

**Deliverables**:
- `scripts/launch-vllm.sh` — reusable vLLM launch script
- `results/phase1/` — validation logs and test outputs
- `docs/README.md` — updated with script documentation

---

## Phase 2: SWE-Bench Default Harness Evaluation

### Step 2.1: Install SWE-bench

```bash
cd ~/Code
git clone https://github.com/SWE-bench/SWE-bench.git
cd SWE-bench
pip install -e .
```

**Verify**: `python -m swebench.harness.run_evaluation --help`

### Step 2.2: Generate Predictions via Inference Pipeline

Use `swebench.inference.run_api` with `OPENAI_BASE_URL` pointing to the local vLLM server:

```bash
export OPENAI_API_KEY="dummy"
export OPENAI_BASE_URL="http://localhost:8888/v1"

python -m swebench.inference.run_api \
  --dataset_name_or_path SWE-bench/SWE-bench_Multilingual \
  --model_name_or_path Qwen/Qwen3-Coder-Next-FP8 \
  --output_dir results/phase2/predictions \
  --split test
```

**Notes**:
- `run_api.py` respects `OPENAI_BASE_URL` for custom endpoints (confirmed)
- Long-running process (300 instances, single concurrent request)
- Check for built-in skip/resume logic for interrupted runs
- Monitor output directory for incremental progress
- Model config: temperature=1.0, top_p=0.95, top_k=40, max_new_tokens=65536

### Step 2.3: Run Evaluation Harness

```bash
python -m swebench.harness.run_evaluation \
  --dataset_name SWE-bench/SWE-bench_Multilingual \
  --predictions_path results/phase2/predictions/<predictions_file>.jsonl \
  --max_workers 8 \
  --run_id phase2-default-harness
```

**Notes**:
- Evaluation runs patches in Docker containers and checks test results
- The ~30 pre-pulled `starryzhang/sweb.eval.x86_64.*` images cover some instances; the harness will pull/build additional images as needed
- Evaluation is CPU-bound (Docker containers) — runs fine alongside the vLLM server
- `--max_workers` should not exceed `min(0.75 * 20, 24)` = 15

### Step 2.4: Generate Reports

Format evaluation results into:
1. **Summary report**: Pass rates, resolved instances by language
2. **Detailed report**: Per-instance results

Create a report generation script if the process is non-trivial. Document any scripts in `docs/README.md`.

**Deliverables**: `results/phase2/` with predictions, evaluation logs, summary report, and detailed report

---

## Phase 3: SWE-Agent Harness Evaluation

### Step 3.0: Rebuild SWE-bench Images as ARM64 ✅ COMPLETE

**Context**: DGX Spark is NVIDIA Grace (ARM64). Solution: rebuild all instances as native ARM64 to avoid QEMU emulation issues.

**Implementation**:
1. ✅ Patched SWE-bench fork to add ARM64 support:
   - Added `--arch` parameter to `prepare_images.py`
   - Modified `dockerfiles/__init__.py` to handle Chrome/Chromium for ARM64
   - Modified `dockerfiles/javascript.py` to support ARM64 pnpm downloads
   - Branch: `arm64-support` at github.com/SailorJoe6/SWE-bench

2. ✅ Patched SWE-agent fork to add ARM64 support:
   - Added `arch` field to `SWEBenchInstances` class
   - Modified image naming to use architecture parameter
   - Updated platform selection (linux/arm64 vs linux/amd64)
   - Branch: `arm64-support` at github.com/SailorJoe6/SWE-agent

3. ✅ Built ARM64 images:
   ```bash
   python -m swebench.harness.prepare_images \
     --dataset_name multilingual \
     --split test \
     --arch arm64 \
     --num_workers 4
   ```

**Results**:
- ✅ 22 base images built (all language/version combinations)
- ✅ 295 instance images built successfully (78% of 377 attempts)
- ⚠️ 82 instances failed (see Failed Container Builds section)
- Images tagged as `sweb.eval.arm64.*` and `docker.io/swebench/sweb.eval.arm64.*`

**Documentation**: Complete implementation guide at `docs/arm64-support/README.md`

**Status**: COMPLETE with 295 working images (sufficient for evaluation)

### Step 3.1: Install SWE-agent

```bash
cd ~/Code
git clone https://github.com/SWE-agent/SWE-agent.git
cd SWE-agent
pip install -e .
```

**Verify**: `sweagent --help` or `python -m sweagent --help`

### Step 3.2: Configure SWE-agent for Local vLLM

SWE-agent uses litellm for model access. Configure for the local vLLM endpoint:

```yaml
# Expected config approach (litellm-compatible)
model:
  name: openai/Qwen/Qwen3-Coder-Next-FP8
  api_base: http://localhost:8888/v1
  api_key: dummy
  temperature: 1.0
  top_p: 0.95
```

Exact configuration format will be determined from SWE-agent documentation during implementation.

### Step 3.3: Tag ARM64 Images for SWE-agent ✅ COMPLETE

**CRITICAL**: Before running evaluation, ALL ARM64 images must be tagged with the format SWE-agent expects.

**Why**: SWE-bench builds images as `sweb.eval.arm64.repo__instance:latest` but SWE-agent expects `docker.io/swebench/sweb.eval.arm64.repo_1776_instance:latest`

**Command**:
```bash
cd ~/Code/swebench-eval-next

# Tag all 295 ARM64 images (fast, ~1 minute)
for img in $(docker images --format "{{.Repository}}:{{.Tag}}" | grep "^sweb.eval.arm64"); do
    REPO=$(echo "$img" | cut -d: -f1)
    TAG=$(echo "$img" | cut -d: -f2)
    INSTANCE_NAME=$(echo "$REPO" | sed 's/sweb.eval.arm64.//')
    NEW_NAME="docker.io/swebench/sweb.eval.arm64.${INSTANCE_NAME//__/_1776_}"
    docker tag "$img" "$NEW_NAME:$TAG"
done
```

**Alternative**: Use provided script:
```bash
bash scripts/tag-arm64-images.sh
```

**Verify**: Check one image is tagged correctly:
```bash
docker images | grep "docker.io/swebench/sweb.eval.arm64" | head -5
```

### Step 3.4: Run SWE-agent Against SWE-bench Multilingual

**Prerequisites**:
- ✅ ARM64 images built (Step 3.0)
- ✅ Images tagged for SWE-agent (Step 3.3)
- ✅ vLLM server running
- ✅ Config file ready

**Output Directory Structure**:
```
results/phase3/
├── test-single/           # Single instance test (apache__druid-13704 - completed)
└── full-run/              # Full 295 instance evaluation (use this for full run)
```

**Command**:
```bash
cd ~/Code/swebench-eval-next
source venv/bin/activate

# Use nohup for multi-day process
nohup sweagent run-batch \
  --config config/qwen3-vllm.yaml \
  --output_dir results/phase3/full-run \
  > results/phase3/full-run.log 2>&1 &
```

**Configuration**:
- Config: `config/qwen3-vllm.yaml` (ARM64 defaults, multilingual dataset)
- Instances: 295 (all successfully built ARM64 images)
- Model: Qwen3-Coder-Next-FP8 via local vLLM (localhost:8888)
- Output: `results/full-arm64-eval/`
- Log: `results/full-arm64-eval.log`

**Monitoring**:
```bash
# View live progress
tail -f results/phase3/full-run.log

# Check running processes
ps aux | grep sweagent

# Count completed instances
ls -1 results/phase3/full-run/*/instance_id.traj 2>/dev/null | wc -l
```

**Expected Duration**: Multiple days (est. 10-20 min per instance × 295 instances = 49-98 hours)

**Notes**:
- Running in sequential mode (single model request constraint)
- SWE-agent has built-in resume logic for interruptions
- Trajectories saved to individual instance directories
- Predictions aggregated in `results/phase3/full-run/preds.json`

### Step 3.5: Evaluate Predictions

Use the SWE-bench evaluation harness to verify SWE-agent's generated patches:

```bash
python -m swebench.harness.run_evaluation \
  --dataset_name SWE-bench/SWE-bench_Multilingual \
  --predictions_path results/phase3/predictions/<predictions_file>.jsonl \
  --max_workers 8 \
  --run_id phase3-swe-agent
```

### Step 3.6: Generate Reports and Preserve Artifacts

Format results into summary and detailed reports. Preserve all JSON prediction files for later inspection.

Create or reuse report generation scripts. Document in `docs/README.md`.

**Deliverables**: `results/phase3/` with predictions, JSON prediction files, evaluation logs, summary report, and detailed report

### Step 3.7: Troubleshoot and Fix Failed ARM64 Container Builds

**Status**: **DONE** - 82 → 6 → 1 unfixable instance

**Resolution Summary**:
- Initial 82 failures were from stale `missing_instances.txt` (early build attempts)
- Only 6 instances truly failed after full build completion
- Fixed 5 preactjs instances (node-gyp Python dependency)
- 1 unfixable: `tokio-rs__tokio-4384` (upstream Cargo.lock mismatch)
- **Final: 299/300 ARM64 images built**

**Root Cause Analysis**:

1. **Preactjs instances (5 fixed)**:
   - `preactjs__preact-{2757,2896,2927,3010,3062}`
   - **Issue**: `_DOCKERFILE_BASE_JS_2` template missing Python
   - `iltorb` npm package requires `node-gyp` → needs Python to build
   - Node 18+ pulls python3 as dependency; Node 16 does not
   - **Fix**: Added `python3 python3-dev` to apt install in template
   - **Commits**: SWE-bench fork `ce4ce87`, `0cc4389`

2. **tokio-rs/tokio-4384 (unfixable)**:
   - Cargo.lock mismatch with `--locked` flag
   - Upstream SWE-bench dataset issue (not ARM64-specific)
   - Cannot fix without modifying test data

**Commands Used**:
```bash
# Delete broken env image to force rebuild
docker rmi sweb.env.js.arm64.e48de95e424f48bce473c9:latest

# Rebuild with fixed template
python -m swebench.harness.prepare_images \
  --dataset_name "swe-bench/SWE-bench_Multilingual" \
  --split test \
  --arch arm64 \
  --tag latest \
  --env_image_tag latest \
  --instance_ids preactjs__preact-{2757,2896,2927,3010,3062}

# Tag for SWE-agent
docker tag sweb.eval.arm64.preactjs__preact-2757:latest \
  docker.io/swebench/sweb.eval.arm64.preactjs_1776_preact-2757:latest
```

**Artifacts**:
- `missing_instances.txt`: Now contains only `tokio-rs__tokio-4384`
- Build logs: `logs/build_images/instances/sweb.eval.arm64.*/`
- Env image Dockerfile: `logs/build_images/env/sweb.env.js.arm64.e48de95e424f48bce473c9__latest/Dockerfile`

**Deliverables**:
- Build log analysis summary
- Categorized failure list by root cause
- Patches/fixes for common issues
- Updated documentation with ARM64 incompatibilities
- Rebuilt instance images (if fixes successful)

---

## Phase 4: mini-SWE-agent Harness Evaluation (Optional)

**Activation**: Only after successful Phase 3 completion and review.

### Step 4.1: Install mini-SWE-agent

```bash
pip install mini-swe-agent
```

**Verify**: `mini --help`

### Step 4.2: Configure for Local vLLM

mini-SWE-agent uses `LitellmModel`, which supports OpenAI-compatible endpoints:

```python
from mini_swe_agent import DefaultAgent, LitellmModel, LocalEnvironment

agent = DefaultAgent(
    LitellmModel(
        model_name="openai/Qwen/Qwen3-Coder-Next-FP8",
        api_base="http://localhost:8888/v1",
    ),
    LocalEnvironment(),
)
```

Exact CLI configuration for batch SWE-bench evaluation will be determined from mini-SWE-agent documentation during implementation.

### Step 4.3: Run Against SWE-bench Multilingual

Run mini-SWE-agent in batch mode. Same parallelism constraints as Phase 3 (2-3 agents max).

### Step 4.4: Evaluate and Report

Same evaluation workflow as Phase 3.

**Deliverables**: `results/phase4/` with predictions, evaluation logs, summary report, and detailed report

---

## Documentation

All scripts, tools, and utilities created during implementation will be documented in `docs/README.md`. This includes:

- Server launch/management scripts
- Report generation scripts
- Any helper utilities for deduplication, resumption, or monitoring
- Configuration files and their purpose

Each new script or tool should include:
- What it does
- Usage instructions
- Any required environment variables or prerequisites

---

## Dependencies

```
Step 0 (Scaffolding) — no deps

Phase 1 (vLLM Setup)
  ├── Step 1.1: Build container (no deps)
  ├── Step 1.2: Download model (no deps, parallel with 1.1)
  ├── Step 1.3: Launch server (depends on 1.1 + 1.2)
  ├── Step 1.4: Validate (depends on 1.3)
  └── Step 1.5: Script + record results (depends on 1.4)

Phase 2 (SWE-Bench Default) — depends on Phase 1 completion
  ├── Step 2.1: Install SWE-bench (can start during Phase 1)
  ├── Step 2.2: Generate predictions (depends on 2.1 + Phase 1)
  ├── Step 2.3: Run evaluation (depends on 2.2)
  └── Step 2.4: Generate reports (depends on 2.3)

Phase 3 (SWE-Agent) — depends on Phase 1; runs AFTER Phase 2
  ├── Step 3.1: Install SWE-agent (can start during Phase 1)
  ├── Step 3.2: Configure (depends on 3.1)
  ├── Step 3.3: Run predictions (depends on 3.2 + Phase 1)
  ├── Step 3.4: Evaluate (depends on 3.3)
  └── Step 3.5: Reports (depends on 3.4)

Phase 4 (mini-SWE-agent, optional) — depends on Phase 3 review
  └── ... same pattern as Phase 3
```

**Sequencing**: Phases 2, 3, and 4 run sequentially (not in parallel). They share the same vLLM server constrained to a single concurrent request. Running inference tasks concurrently would provide no throughput benefit and add complexity.
