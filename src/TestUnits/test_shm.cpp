#include "gtest/gtest/gtest.h"
#include "../WtShareHelper/WtShareHelper.h"
#include "../Share/StdUtils.hpp"
#include "../Share/StrUtil.hpp"
#include <boost/filesystem.hpp>

TEST(test_shm, test_sharehelper)
{
#ifdef _WIN32
	std::string base_path = "E:\\deploy_uft\\uft_test\\.share";
#else
	std::string base_path = boost::filesystem::temp_directory_path().string() + "/uft_test.shm";
#endif
	std::string shm_path = StrUtil::standardisePath(base_path);

	// First initialize as master to set up the shared memory
	EXPECT_TRUE(init_master("uft", shm_path.c_str()));

	//EXPECT_TRUE(set_string("test", "section", "string", "value"));
	//EXPECT_TRUE(set_string("test", "section", "string", "value2"));
	//EXPECT_TRUE(set_int32("test", "section", "int32", -5));
	//EXPECT_TRUE(set_int32("test", "section", "int32", 5));
	//EXPECT_TRUE(set_int64("test", "section", "int64", -1968759));
	//EXPECT_TRUE(set_int64("test", "section", "int64", 1968759));
	//EXPECT_TRUE(set_uint32("test", "section", "uint32", 0xFFFF0000));
	//EXPECT_TRUE(set_uint32("test", "section", "uint32", 0xFFFF0002));
	//EXPECT_TRUE(set_uint64("test", "section", "uint64", 0xFFFFFFFF00000000));
	//EXPECT_TRUE(set_uint64("test", "section", "uint64", 0xFFFFFFFF00000003));
	//EXPECT_TRUE(set_double("test", "section", "double", DBL_MAX));
	//EXPECT_TRUE(set_double("test", "section", "double", FLT_MAX));

	// Set initial values
	EXPECT_TRUE(set_int32("uft", "uft_demo", "offset", 1));
	EXPECT_TRUE(set_uint32("uft", "uft_demo", "second", 10));
	EXPECT_TRUE(set_double("uft", "uft_demo", "lots", 1.0));

	// Now initialize as slave to read the values
	EXPECT_TRUE(init_slave("uft", shm_path.c_str()));

	// Verify the values
	EXPECT_EQ(get_int32("uft", "uft_demo", "offset"), 1);
	EXPECT_EQ(get_uint32("uft", "uft_demo", "second"), 10);
	EXPECT_EQ(get_double("uft", "uft_demo", "lots"), 1.0);

	// Clean up
	release_slave("uft");
}
