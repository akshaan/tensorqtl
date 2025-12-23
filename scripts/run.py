#!/usr/bin/env python3
import argparse
import json
import subprocess
import shutil
from pathlib import Path

from tensorqtl.dataset import DATASETS


def run_command(cmd, check=True, shell=False, env=None):
    """Run a shell command and return the result."""
    if isinstance(cmd, str):
        shell = True
    result = subprocess.run(cmd, shell=shell, check=check, env=env, 
                          capture_output=False, text=True)
    return result


def check_cuda_available():
    """Check if CUDA is available by checking for nvidia-smi."""
    return shutil.which("nvidia-smi") is not None


def construct_output_dir(dataset: str, mode: str, compile: bool, profile_type: str = None) -> Path:
    compile_suffix = 'compile' if compile else 'raw'
    profile_suffix = profile_type if profile_type else 'noprofile'
    script_path = Path(__file__).parent.parent
    return Path(f"{script_path}/runs/{dataset}_{mode}_{compile_suffix}_{profile_suffix}")


def build_tensorqtl_cmd(
    output_dir: Path,
    dataset: str,
    mode: str,
    compile_mode: bool = False, 
    profile_type: str = None, 
    quiet: bool = True,
):
    """Build the tensorqtl command with specified options."""

    dataset = next(d for d in DATASETS if d.name == dataset)
    if mode not in dataset.modes:
        raise ValueError(f"Mode {mode} is not supported for dataset {dataset.name}")

    cmd = [
        "python3", "-m", "tensorqtl",
        str(dataset.genotype_path),
        str(dataset.phenotype_path),
        str(dataset.output_prefix),
        "--covariates", str(dataset.covariates_path),
        "--mode", mode,
        "--output_dir", str(output_dir / "output"),
        "--torch_profile_dir", str(output_dir / "pytorch"),
    ]
    
    if quiet:
        cmd.append("--quiet")
    
    if compile_mode:
        cmd.append("--compile")
    
    if profile_type == "pytorch":
        cmd.append("--profile")
    
    return cmd


def run_tensorqtl(
    output_dir: Path, 
    dataset: str,
    mode: str,
    compile_mode: bool = False, 
    profile_type: str = None,
    quiet: bool = True
):
    """
    Run tensorqtl with specified options.
    
    profile_type can be:
        - "pytorch": Run with PyTorch profiling only
        - "nsys": Run with NSYS profiling only (requires CUDA)
        - "ncu": Run with NCU profiling only (requires CUDA)
        - None: Regular run without profiling
    """
    tensorqtl_cmd = build_tensorqtl_cmd(
        output_dir, dataset, mode, compile_mode, profile_type, quiet
    )
    
    if profile_type == "ncu":
        # Run with NCU profiling only
        if not check_cuda_available():
            print("Warning: CUDA not available, skipping NCU profiling.")
            return
        
        print("Running with NCU profiling...")
        cmd = [
            "ncu", "--metrics",
            "dram__throughput.avg.pct_of_peak_sustained_elapsed,"
            "sm__throughput.avg.pct_of_peak_sustained_elapsed,"
            "smsp__stall_long_scoreboard.avg.pct",
            "-o", str(output_dir / "ncu" / output_dir.name),
        ]
        cmd.extend(tensorqtl_cmd)
        run_command(cmd)
    elif profile_type == "nsys":
        # Run with NSYS profiling only
        if not check_cuda_available():
            print("Warning: CUDA not available, skipping NSYS profiling.")
            return
        
        print("Running with NSYS profiling...")
        nsight_output = output_dir / "nsys" / output_dir.name
        cmd = [
            "nsys", "profile",
            "--force-overwrite", "true",
            "--output", str(nsight_output),
            "--trace=cuda,nvtx,osrt,cudnn,cublas",
        ]
        cmd.extend(tensorqtl_cmd)
        run_command(cmd)
    elif profile_type == "pytorch":
        # Run with PyTorch profiling only
        print("Running with PyTorch profiling...")
        run_command(tensorqtl_cmd)
    else:
        # Regular run without profiling
        run_command(tensorqtl_cmd)


def main():
    parser = argparse.ArgumentParser(
        description="Run tensorqtl with optional profiling",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
            Examples:
            # Basic run
            python scripts/run.py
            
            # Run with compilation
            python scripts/run.py --compile
            
            # Run with PyTorch profiling
            python scripts/run.py --profile-type pytorch
            
            # Run with NSYS profiling
            python scripts/run.py --profile-type nsys
            
            # Run with NCU profiling
            python scripts/run.py --profile-type ncu
            
            # Run with compilation and profiling
            python scripts/run.py --compile --profile-type pytorch
        """
    )
    
    parser.add_argument(
        "--output-dir",
        type=str,
        default=None,
        help="Output directory"
    )
    
    parser.add_argument(
        "--compile", "-c",
        action="store_true",
        help="Enable compilation mode"
    )
    
    parser.add_argument(
        "--profile-type",
        type=str,
        choices=["ncu", "nsys", "pytorch"],
        default=None,
        help="Type of profiling to enable: 'ncu' for NCU profiling, 'nsys' for NSYS profiling, "
             "or 'pytorch' for PyTorch profiling. Only the specified profiler will be run."
    )
    
    parser.add_argument(
        "--no-quiet",
        action="store_true",
        help="Disable quiet mode"
    )

    parser.add_argument(
        "--dataset",
        type=str,
        default="geuvadis",
        choices=[x.name for x in DATASETS],
        help="Dataset to use"
    )

    parser.add_argument(
        "--mode",
        type=str,
        default="cis",
        choices=["cis", "trans"],
        help="Mapping mode"
    )
    
    args = parser.parse_args()
    
    # Determine output directory
    if args.output_dir:
        output_dir = Path(args.output_dir)
    else:
        output_dir = construct_output_dir(args.dataset, args.mode, args.compile, args.profile_type)
    
    # Create output directories
    if args.profile_type == "ncu":
        (output_dir / "ncu").mkdir(parents=True, exist_ok=True)
    elif args.profile_type == "nsys":
        (output_dir / "nsys").mkdir(parents=True, exist_ok=True)
    elif args.profile_type == "pytorch":
        (output_dir / "pytorch").mkdir(parents=True, exist_ok=True)
    (output_dir / "output").mkdir(parents=True, exist_ok=True)
    
    # Write args dict to json in output directory
    (output_dir / "args.json").write_text(json.dumps(args.__dict__, indent=4))
    
    # Run tensorqtl
    run_tensorqtl(
        output_dir,
        dataset=args.dataset,
        mode=args.mode,
        compile_mode=args.compile,
        profile_type=args.profile_type,
        quiet=not args.no_quiet
    )


if __name__ == "__main__":
    main()

