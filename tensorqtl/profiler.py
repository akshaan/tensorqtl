import os
import torch


class pytorch_profiler:
    """
    Context manager for PyTorch profiling that exports Chrome traces.
    
    Usage:
        with pytorch_profiler(profile_dir="/path/to/traces"):
            # your code here
            if profiler is not None:
                profiler.step()
    """
    
    def __init__(self, profile_dir=None):
        """
        Args:
            profile_dir: Directory where Chrome trace files will be saved.
                        If None, profiling is disabled.
        """
        self.profiler = None
        if profile_dir:
            # Ensure the profile directory exists
            os.makedirs(profile_dir, exist_ok=True)
            # Create chrome trace handler
            trace_counter = [0]  # Use list to allow modification in closure
            def chrome_trace_handler(prof):
                trace_file = os.path.join(profile_dir, f"trace_{trace_counter[0]}.json")
                prof.export_chrome_trace(trace_file)
                trace_counter[0] += 1
            
            self.profiler = torch.profiler.profile(
                activities=[torch.profiler.ProfilerActivity.CPU, torch.profiler.ProfilerActivity.CUDA],
                schedule=torch.profiler.schedule(wait=0, warmup=1, active=10, repeat=1),
                on_trace_ready=chrome_trace_handler,
                record_shapes=True,
                profile_memory=True,
                with_stack=True,
                with_flops=False,
                experimental_config=None
            )
    
    def __enter__(self):
        if self.profiler:
            return self.profiler.__enter__()
        return None
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.profiler:
            return self.profiler.__exit__(exc_type, exc_val, exc_tb)
        return False

