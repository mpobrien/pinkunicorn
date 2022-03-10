package io.realm.pinkunicorn

import android.os.Bundle
import androidx.fragment.app.Fragment
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.navigation.fragment.findNavController
import io.realm.log.RealmLog
import io.realm.mongodb.App
import io.realm.mongodb.Credentials
import io.realm.mongodb.User
import io.realm.pinkunicorn.UnicornApplication.Companion.APP
import io.realm.pinkunicorn.databinding.FragmentFirstBinding

/**
 * A simple [Fragment] subclass as the default destination in the navigation.
 */
class FirstFragment : Fragment() {

    private var _binding: FragmentFirstBinding? = null

    // This property is only valid between onCreateView and
    // onDestroyView.
    private val binding get() = _binding!!

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        _binding = FragmentFirstBinding.inflate(inflater, container, false)
        return binding.root

    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        binding.buttonLogin.setOnClickListener {
            APP.loginAsync(Credentials.anonymous()) { result: App.Result<User> ->
                if (result.isSuccess) {
                    gotoBoards()
                } else {
                    RealmLog.debug(result.error.toString())
                    Toast.makeText(context, "An error occurred.", Toast.LENGTH_LONG).show()
                }
            }
        }

        if (APP.currentUser() != null) {
            gotoBoards()
        }
    }

    private fun gotoBoards() {
        findNavController().navigate(R.id.action_FirstFragment_to_SecondFragment)
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}