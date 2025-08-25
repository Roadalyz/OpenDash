import subprocess
import pytest
import os
import time
import signal
from pathlib import Path


class TestDashcamApplication:
    """System tests for the dashcam application"""
    
    @pytest.fixture
    def build_dir(self):
        """Get the build directory path"""
        # Assuming build directory is at project root
        return Path(__file__).parent.parent.parent / "build"
    
    @pytest.fixture
    def executable_path(self, build_dir):
        """Get the path to the dashcam executable"""
        if os.name == 'nt':  # Windows
            return build_dir / "src" / "Debug" / "dashcam_main.exe"
        else:  # Unix-like
            return build_dir / "src" / "dashcam_main"
    
    def test_application_starts_and_stops(self, executable_path):
        """Test that the application starts and can be stopped cleanly"""
        assert executable_path.exists(), f"Executable not found at {executable_path}"
        
        # Start the application
        process = subprocess.Popen(
            [str(executable_path)],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        
        # Let it run for a short time
        time.sleep(2)
        
        # Send SIGTERM to trigger clean shutdown
        process.terminate()
        
        # Wait for it to exit
        stdout, stderr = process.communicate(timeout=10)
        
        # Check that it exited cleanly
        # On Unix: 0 (clean exit) or -15 (SIGTERM)
        # On Windows: 0 (clean exit) or 1 (terminated)
        if os.name == 'nt':  # Windows
            assert process.returncode == 0 or process.returncode == 1
        else:  # Unix-like
            assert process.returncode == 0 or process.returncode == -15
        
        # Check that it produced some output
        assert "Dashcam application starting up" in stderr or "Dashcam application starting up" in stdout
    
    def test_application_handles_sigint(self, executable_path):
        """Test that the application handles SIGINT (Ctrl+C) gracefully"""
        if os.name == 'nt':
            pytest.skip("SIGINT test not applicable on Windows")
        
        assert executable_path.exists(), f"Executable not found at {executable_path}"
        
        # Start the application
        process = subprocess.Popen(
            [str(executable_path)],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        
        # Let it run for a short time
        time.sleep(1)
        
        # Send SIGINT
        process.send_signal(signal.SIGINT)
        
        # Wait for it to exit
        stdout, stderr = process.communicate(timeout=10)
        
        # Check that it handled the signal appropriately
        # The application should exit cleanly when receiving SIGINT (graceful shutdown)
        # On Unix: 0 (clean exit) or -2 (SIGINT) are both acceptable
        assert process.returncode == 0 or process.returncode == -2
    
    def test_application_creates_log_files(self, executable_path, tmp_path):
        """Test that the application creates log files"""
        assert executable_path.exists(), f"Executable not found at {executable_path}"
        
        # Change to a temporary directory
        original_cwd = os.getcwd()
        try:
            os.chdir(tmp_path)
            
            # Start the application
            process = subprocess.Popen(
                [str(executable_path)],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            
            # Let it run for a short time
            time.sleep(2)
            
            # Stop it
            process.terminate()
            process.communicate(timeout=10)
            
            # Check that log directory was created
            log_dir = tmp_path / "logs"
            assert log_dir.exists(), "Log directory was not created"
            
            # Check that log file was created
            log_files = list(log_dir.glob("*.log"))
            assert len(log_files) > 0, "No log files were created"
            
            # Check that log file contains expected content
            log_content = log_files[0].read_text()
            assert "Dashcam application starting up" in log_content
            
        finally:
            os.chdir(original_cwd)
    
    def test_application_version_info(self, executable_path):
        """Test that build type information is logged correctly"""
        assert executable_path.exists(), f"Executable not found at {executable_path}"
        
        # Start the application
        process = subprocess.Popen(
            [str(executable_path)],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        
        # Let it run briefly
        time.sleep(1)
        
        # Stop it
        process.terminate()
        stdout, stderr = process.communicate(timeout=10)
        
        # Check that build type is mentioned
        output = stdout + stderr
        assert "Build type:" in output
        assert ("Debug" in output) or ("Release" in output)


class TestDashcamIntegration:
    """Integration tests for dashcam components"""
    
    def test_logger_integration(self, tmp_path):
        """Test logger integration with real file system"""
        # This test can be expanded when more components are implemented
        pass
    
    def test_configuration_loading(self, tmp_path):
        """Test configuration file loading"""
        # This test can be implemented when config parser is ready
        pass


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
