package com.sangcv.ffi_flutter.adapter

import android.content.res.ColorStateList
import android.graphics.Color
import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.RecyclerView
import com.sangcv.ffi_flutter.databinding.ImageFilterBinding
import com.sangcv.ffi_flutter.model.ImageFilterData


interface ImageFilterAction {
    fun onClick(imageFilter: ImageFilterData)
}

class ImageFilterAdapter(
    private val imageFilters: List<ImageFilterData>,
    private val imageFilterAction: ImageFilterAction
) :
    RecyclerView.Adapter<ImageFilterAdapter.ImageFilterViewHolder>() {

    private var selectedIndex: Int = 0

    inner class ImageFilterViewHolder(
        private val binding: ImageFilterBinding
    ) :
        RecyclerView.ViewHolder(binding.root) {

        fun bind(
            imageFilter: ImageFilterData,
            imageFilterAction: ImageFilterAction,
            position: Int
        ) {

            binding.imgFilter.setImageBitmap(imageFilter.bitmap)

            if (position == selectedIndex) {
                val states = arrayOf(
                    intArrayOf(android.R.attr.state_enabled)
                )

                val colors = intArrayOf(
                    Color.WHITE
                )

                val myList = ColorStateList(states, colors)

                binding.imgFilter.strokeColor = myList
                binding.imgFilter.strokeWidth = 5f
            } else {
                binding.imgFilter.strokeColor = null

            }

            binding.imgFilter.setOnClickListener {
                val lastSelectedIndex = selectedIndex
                selectedIndex = position
                notifyItemChanged(position)
                notifyItemChanged(lastSelectedIndex)
                imageFilterAction.onClick(imageFilter)
            }
            binding.executePendingBindings()
        }
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ImageFilterViewHolder {
        val layoutInflater: LayoutInflater = LayoutInflater.from(parent.context)
        val binding: ImageFilterBinding = ImageFilterBinding.inflate(
            layoutInflater, parent, false
        )
        return ImageFilterViewHolder(binding)
    }

    override fun onBindViewHolder(holderImageFilter: ImageFilterViewHolder, position: Int) {
        val imageFilter = imageFilters[position]
        holderImageFilter.bind(imageFilter, imageFilterAction, position)
    }

    override fun getItemCount(): Int {
        return imageFilters.size
    }
}