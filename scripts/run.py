#!/usr/bin/env python3
import argparse
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


def build_tensorqtl_cmd(
    output_dir: Path,
    dataset: str,
    mode: str,
    compile_mode: bool = False, 
    profile: bool = False, 
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
        "GEUVADIS.445_samples",
        "--covariates", str(dataset.covariates_path),
        "--mode", mode,
        "--output_dir", str(output_dir / "output"),
        "--torch_profile_dir", str(output_dir / "pytorch"),
    ]
    
    if quiet:
        cmd.append("--quiet")
    
    if compile_mode:
        cmd.append("--compile")
    
    if profile:
        cmd.append("--profile")
    
    return cmd


def run_tensorqtl(
    output_dir: Path, 
    dataset: str,
    mode: str,
    compile_mode: bool = False, 
    profile: bool = False,
    use_ncu: bool = False, 
    quiet: bool = True
):
    """
    Run tensorqtl with specified options.
    
    When profile=True:
        - PyTorch profiling is always enabled
        - Optionally wraps with NSYS (default) or NCU (if use_ncu=True)
        - NSYS/NCU is skipped if CUDA is not available
    """
    tensorqtl_cmd = build_tensorqtl_cmd(
        output_dir, dataset, mode, compile_mode, profile, quiet
    )
    
    # If profiling is enabled, wrap with NSYS or NCU
    if profile:
        if use_ncu:
            # Run with NCU profiling
            if not check_cuda_available():
                print("Warning: CUDA not available, skipping NCU profiling. Running with PyTorch profiling only.")
                run_command(tensorqtl_cmd)
                return
            
            print("Running with NCU and PyTorch profiling...")
            cmd = [
                "ncu", "--metrics",
                "dram__throughput.avg.pct_of_peak_sustained_elapsed,"
                "sm__throughput.avg.pct_of_peak_sustained_elapsed,"
                "smsp__stall_long_scoreboard.avg.pct",
            ]
            cmd.extend(tensorqtl_cmd)
            run_command(cmd)
        else:
            # Run with NSYS profiling (default)
            if not check_cuda_available():
                print("Warning: CUDA not available, skipping NSYS profiling. Running with PyTorch profiling only.")
                run_command(tensorqtl_cmd)
                return
            
            print("Running with NSYS and PyTorch profiling...")
            nsight_output = output_dir / "nsight" / output_dir.name
            cmd = [
                "nsys", "profile",
                "--force-overwrite", "true",
                "--output", str(nsight_output),
                "--trace=cuda,nvtx,osrt,cudnn,cublas",
            ]
            cmd.extend(tensorqtl_cmd)
            run_command(cmd)
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
            
            # Run with profiling (PyTorch + NSYS)
            python scripts/run.py --profile
            
            # Run with profiling using NCU instead of NSYS
            python scripts/run.py --profile --use-ncu
            
            # Run with compilation and profiling
            python scripts/run.py --compile --profile
        """
    )
    
    parser.add_argument(
        "--output-dir",
        type=str,
        default=None,
        help="Output directory (default: ./runs/cis_compile or ./runs/cis_raw based on --compile)"
    )
    
    parser.add_argument(
        "--compile", "-c",
        action="store_true",
        help="Enable compilation mode"
    )
    
    parser.add_argument(
        "--profile",
        action="store_true",
        help="Enable profiling (PyTorch + NSYS/NCU). PyTorch profiling is always enabled. "
             "NSYS is used by default, or NCU if --use-ncu is specified. "
             "NSYS/NCU is skipped if CUDA is not available."
    )
    
    parser.add_argument(
        "--use-ncu",
        action="store_true",
        help="Use NCU instead of NSYS for profiling (requires --profile). "
             "Ignored if CUDA is not available."
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
    
    # Validate arguments
    if args.use_ncu and not args.profile:
        parser.error("--use-ncu requires --profile to be specified")
    
    # Determine output directory
    if args.output_dir:
        output_dir = Path(args.output_dir)
    elif args.compile:
        output_dir = Path("runs/cis_compile")
    else:
        output_dir = Path("runs/cis_raw")
    
    # Create output directories
    (output_dir / "nsight").mkdir(parents=True, exist_ok=True)
    (output_dir / "pytorch").mkdir(parents=True, exist_ok=True)
    (output_dir / "output").mkdir(parents=True, exist_ok=True)
    
    # Run tensorqtl
    run_tensorqtl(
        output_dir,
        dataset=args.dataset,
        mode=args.mode,
        compile_mode=args.compile,
        profile=args.profile,
        use_ncu=args.use_ncu,
        quiet=not args.no_quiet
    )


if __name__ == "__main__":
    main()

